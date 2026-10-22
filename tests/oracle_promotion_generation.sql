rem Run ONLY in a dedicated EMPTY test schema, never in SH or an admin schema.
rem Creates minimal fixtures and the real SH_DATA_GENERATION package.
rem All test DML is rolled back; test objects remain for manual inspection.

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF
SET SERVEROUTPUT ON
ALTER SESSION SET NLS_CALENDAR='GREGORIAN';

DECLARE
   v_objects NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_objects FROM user_objects;
   IF USER IN ('SYS', 'SYSTEM', 'ADMIN', 'SH') OR v_objects != 0
      OR SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') != USER THEN
      RAISE_APPLICATION_ERROR(-20890, 'Regression tests require a dedicated EMPTY non-admin, non-SH schema.');
   END IF;
END;
/

CREATE TABLE products (prod_id NUMBER(6) PRIMARY KEY, prod_list_price NUMBER(8,2), prod_min_price NUMBER(8,2));
CREATE TABLE customers (cust_id NUMBER PRIMARY KEY);
CREATE TABLE channels (channel_id NUMBER(1) PRIMARY KEY);
CREATE TABLE times (time_id DATE PRIMARY KEY);
CREATE TABLE promotions (
   promo_id NUMBER(6) PRIMARY KEY, promo_name VARCHAR2(30) NOT NULL,
   promo_subcategory VARCHAR2(30) NOT NULL, promo_subcategory_id NUMBER NOT NULL,
   promo_category VARCHAR2(30) NOT NULL, promo_category_id NUMBER NOT NULL,
   promo_cost NUMBER(10,2) NOT NULL,
   promo_begin_date DATE NOT NULL, promo_end_date DATE NOT NULL,
   promo_total VARCHAR2(15) NOT NULL, promo_total_id NUMBER NOT NULL);
rem FKs are intentionally absent, matching initialization's disabled-FK stage.
CREATE TABLE sales (
   prod_id NUMBER(6) NOT NULL, cust_id NUMBER NOT NULL, time_id DATE NOT NULL,
   channel_id NUMBER(1) NOT NULL, promo_id NUMBER(6) NOT NULL,
   quantity_sold NUMBER(3) NOT NULL, amount_sold NUMBER(10,2) NOT NULL);
CREATE TABLE costs (
   prod_id NUMBER NOT NULL, time_id DATE NOT NULL, promo_id NUMBER NOT NULL,
   channel_id NUMBER NOT NULL, unit_cost NUMBER(10,2) NOT NULL, unit_price NUMBER(10,2) NOT NULL);
CREATE TABLE test_expected_sales AS SELECT * FROM sales WHERE 1 = 0;
CREATE TABLE test_expected_costs AS SELECT * FROM costs WHERE 1 = 0;
CREATE TABLE test_expected_promotions AS SELECT * FROM promotions WHERE 1 = 0;

@@../sales_history/sh_data_generation.sql

INSERT INTO products VALUES (13, 100, 75);
INSERT INTO products VALUES (14, 199.99, 140);
INSERT INTO customers VALUES (1);
INSERT INTO customers VALUES (2);
INSERT INTO channels VALUES (2);
INSERT INTO channels VALUES (3);

DECLARE
   v_sales NUMBER;
   v_costs NUMBER;
   v_count NUMBER;
   v_expired_promo NUMBER;

   PROCEDURE assert_true(p_ok BOOLEAN, p_message VARCHAR2) IS
   BEGIN
      IF p_ok IS NULL OR NOT p_ok THEN
         RAISE_APPLICATION_ERROR(-20891, p_message);
      END IF;
      DBMS_OUTPUT.PUT_LINE('PASS: ' || p_message);
   END;

   PROCEDURE generate(p_start DATE, p_end DATE) IS
   BEGIN
      INSERT INTO times SELECT p_start + LEVEL - 1 FROM dual
         CONNECT BY LEVEL <= p_end - p_start + 1;
      sh_data_generation.generate_facts(p_start, p_end, v_sales, v_costs);
      assert_true(v_sales > 0 AND v_costs > 0, 'Nonempty generation ' || TO_CHAR(p_start, 'YYYY-MM-DD'));
   END;

   PROCEDURE clear_generated IS
   BEGIN
      DELETE FROM costs;
      DELETE FROM sales;
      DELETE FROM times;
      DELETE FROM promotions;
   END;

   PROCEDURE assert_same(p_table VARCHAR2) IS
      v_columns VARCHAR2(1000);
      v_actual VARCHAR2(2000);
      v_expected VARCHAR2(2000);
      v_diff NUMBER;
   BEGIN
      -- Fixed whitelist, never accept arbitrary identifiers in this helper.
      CASE p_table
         WHEN 'sales' THEN v_columns := 'prod_id,cust_id,time_id,channel_id,promo_id,quantity_sold,amount_sold';
         WHEN 'costs' THEN v_columns := 'prod_id,time_id,promo_id,channel_id,unit_cost,unit_price';
         WHEN 'promotions' THEN v_columns := 'promo_id,promo_name,promo_subcategory,promo_subcategory_id,' ||
            'promo_category,promo_category_id,promo_cost,promo_begin_date,promo_end_date,promo_total,promo_total_id';
         ELSE RAISE_APPLICATION_ERROR(-20892, 'Unknown fixture table');
      END CASE;
      -- Compare multisets, not just distinct rows or aggregate sums.
      v_actual := 'SELECT ' || v_columns || ',COUNT(*) n FROM ' || p_table || ' GROUP BY ' || v_columns;
      v_expected := 'SELECT ' || v_columns || ',COUNT(*) n FROM test_expected_' || p_table || ' GROUP BY ' || v_columns;
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' ||
         'SELECT * FROM (' || v_actual || ' MINUS ' || v_expected || ') UNION ALL ' ||
         'SELECT * FROM (' || v_expected || ' MINUS ' || v_actual || '))' INTO v_diff;
      assert_true(v_diff = 0, 'Identical one-shot / segmented ' || p_table);
   END;

   PROCEDURE expect_invalid(p_code NUMBER) IS
   BEGIN
      BEGIN
         sh_data_generation.validate_range(DATE '2023-12-29', DATE '2024-03-02');
      EXCEPTION
         WHEN OTHERS THEN
            IF SQLCODE = p_code THEN
               DBMS_OUTPUT.PUT_LINE('PASS: validation rejected fixture with ' || p_code);
               RETURN;
            END IF;
            RAISE;
      END;
      RAISE_APPLICATION_ERROR(-20893, 'Expected validation error ' || p_code);
   END;
BEGIN
   -- One-shot generation spans a year boundary, overlapping activities,
   -- partial first/last months, and February 29.
   generate(DATE '2023-12-29', DATE '2024-03-02');
   INSERT INTO test_expected_sales SELECT * FROM sales;
   INSERT INTO test_expected_costs SELECT * FROM costs;
   INSERT INTO test_expected_promotions SELECT * FROM promotions;

   SELECT COUNT(*) INTO v_count FROM promotions;
   assert_true(v_count = 13, 'Three campaigns per touched month plus sentinel');
   SELECT COUNT(*) INTO v_count FROM promotions
    WHERE promo_id != 999
      AND (promo_end_date - promo_begin_date > 14
           OR TRUNC(promo_begin_date, 'MM') != TRUNC(promo_end_date, 'MM'));
   assert_true(v_count = 0, 'Ordinary campaigns remain short and within one month');
   SELECT COUNT(*) INTO v_count FROM sales s JOIN products p ON p.prod_id = s.prod_id
    WHERE s.promo_id = 999 AND s.amount_sold != ROUND(p.prod_list_price * s.quantity_sold, 2);
   assert_true(v_count = 0, 'No-promotion sales use full list price');
   SELECT COUNT(*) INTO v_count FROM sales WHERE promo_id = 999;
   assert_true(v_count > 0, 'No-promotion sales are generated');
   SELECT COUNT(*) INTO v_count FROM sales WHERE promo_id != 999;
   assert_true(v_count > 0, 'Real-promotion sales are generated');
   SELECT COUNT(*) INTO v_count FROM sales s
    WHERE NOT EXISTS (SELECT 1 FROM costs c WHERE c.prod_id = s.prod_id AND c.time_id = s.time_id
                       AND c.promo_id = s.promo_id AND c.channel_id = s.channel_id);
   assert_true(v_count = 0, 'Every sales combination has a cost row');
   SELECT COUNT(*) INTO v_count FROM (
      SELECT prod_id, time_id, promo_id, channel_id FROM costs
       GROUP BY prod_id, time_id, promo_id, channel_id HAVING COUNT(*) > 1);
   assert_true(v_count = 0, 'No duplicate cost combinations');

   clear_generated;
   generate(DATE '2023-12-29', DATE '2024-01-14');
   generate(DATE '2024-01-15', DATE '2024-02-28');
   generate(DATE '2024-02-29', DATE '2024-02-29');
   generate(DATE '2024-03-01', DATE '2024-03-02');
   assert_same('sales');
   assert_same('costs');
   assert_same('promotions');

   SAVEPOINT valid_fixture;
   SELECT MIN(promo_id) INTO v_expired_promo FROM promotions WHERE promo_end_date < DATE '2024-01-01';

   UPDATE sales SET promo_id = v_expired_promo WHERE time_id = DATE '2024-02-29' AND ROWNUM = 1;
   expect_invalid(-20982);
   ROLLBACK TO valid_fixture;

   UPDATE costs SET promo_id = v_expired_promo WHERE time_id = DATE '2024-02-29' AND ROWNUM = 1;
   expect_invalid(-20983);
   ROLLBACK TO valid_fixture;

   UPDATE sales SET promo_id = 998 WHERE ROWNUM = 1;
   expect_invalid(-20982);
   ROLLBACK TO valid_fixture;

   UPDATE costs SET promo_id = 998 WHERE ROWNUM = 1;
   expect_invalid(-20983);
   ROLLBACK TO valid_fixture;

   UPDATE promotions SET promo_begin_date = promo_end_date + 1 WHERE promo_id = v_expired_promo;
   expect_invalid(-20981);
   ROLLBACK TO valid_fixture;

   UPDATE promotions SET promo_begin_date = DATE '9999-01-01', promo_end_date = DATE '9999-01-01'
    WHERE promo_id = 999;
   expect_invalid(-20982);
   ROLLBACK TO valid_fixture;

   DELETE FROM sales WHERE ROWNUM = 1;
   expect_invalid(-20985);
   ROLLBACK TO valid_fixture;

   DELETE FROM times WHERE time_id = DATE '2024-02-29';
   expect_invalid(-20984);
   ROLLBACK TO valid_fixture;

   -- If every candidate is invalid, generation must FAIL, not succeed with
   -- zero rows. MERGE must not silently repair/rewrite existing campaigns.
   DELETE FROM costs;
   DELETE FROM sales;
   UPDATE promotions SET promo_begin_date = DATE '2000-01-01', promo_end_date = DATE '2000-01-02';
   BEGIN
      sh_data_generation.generate_facts(DATE '2023-12-29', DATE '2024-03-02', v_sales, v_costs);
      RAISE_APPLICATION_ERROR(-20894, 'Missing candidates must not silently drop all facts');
   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE != -20985 THEN RAISE; END IF;
   END;
   ROLLBACK TO valid_fixture;
   assert_same('sales');
   assert_same('costs');
   assert_same('promotions');

   clear_generated;
   generate(DATE '2024-01-01', DATE '2024-12-31');
   assert_true(v_sales = 200000, 'Leap year produces exactly 200000 sales');
   SELECT COUNT(*) INTO v_count FROM promotions;
   assert_true(v_count = 37, 'Full year creates 36 campaigns plus sentinel');

   clear_generated;
   generate(DATE '2030-12-31', DATE '2030-12-31');
   assert_true(v_sales = 548, 'Future single-day range retains its exact daily quota');
   SELECT COUNT(*) INTO v_count FROM promotions;
   assert_true(v_count = 4, 'Single-day range creates complete monthly campaigns');
   SELECT COUNT(*) INTO v_count FROM promotions
    WHERE promo_id != 999 AND promo_begin_date = DATE '2030-12-01' AND promo_end_date = DATE '2030-12-14';
   assert_true(v_count = 1, 'Partial range does not clip campaign windows');

   ROLLBACK;
   DBMS_OUTPUT.PUT_LINE('ALL ORACLE GENERATOR TESTS PASSED. Test DML rolled back; fixture objects remain.');
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
END;
/
