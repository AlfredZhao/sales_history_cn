rem Shared, transaction-neutral generator used by initialization and append.
rem Install after sh_create.sql. PROMOTIONS is generated, not loaded from CSV.

CREATE OR REPLACE PACKAGE sh_data_generation AUTHID DEFINER AS
   c_seed CONSTANT PLS_INTEGER := 20260909;

   PROCEDURE generate_facts(
      p_start_date IN DATE, p_end_date IN DATE,
      p_sales_rows OUT NUMBER, p_cost_rows OUT NUMBER);

   PROCEDURE validate_range(p_start_date IN DATE, p_end_date IN DATE);
END sh_data_generation;
/

CREATE OR REPLACE PACKAGE BODY sh_data_generation AS
   c_rows_per_year CONSTANT PLS_INTEGER := 200000;

   PROCEDURE check_range(p_start_date IN DATE, p_end_date IN DATE) IS
   BEGIN
      IF p_start_date IS NULL OR p_end_date IS NULL
         OR p_start_date > p_end_date
         OR p_start_date != TRUNC(p_start_date)
         OR p_end_date != TRUNC(p_end_date) THEN
         RAISE_APPLICATION_ERROR(-20980, '生成范围必须是有效的自然日起止日期。');
      END IF;
   END check_range;

   PROCEDURE ensure_promotions(p_start_date IN DATE, p_end_date IN DATE) IS
      v_first_month DATE := TRUNC(p_start_date, 'MM');
      v_month_count PLS_INTEGER :=
         (EXTRACT(YEAR FROM p_end_date) - EXTRACT(YEAR FROM p_start_date)) * 12
         + EXTRACT(MONTH FROM p_end_date) - EXTRACT(MONTH FROM p_start_date) + 1;
   BEGIN
      -- 999 is a dimension sentinel, NOT a real campaign. Its technical
      -- validity covers all AD dates so every fact obeys the same date rule.
      MERGE INTO promotions p
      USING (SELECT 999 promo_id FROM dual) s
         ON (p.promo_id = s.promo_id)
      WHEN NOT MATCHED THEN INSERT (
         promo_id, promo_name, promo_subcategory, promo_subcategory_id,
         promo_category, promo_category_id, promo_cost,
         promo_begin_date, promo_end_date, promo_total, promo_total_id)
      VALUES (s.promo_id, '无促销', '无促销', 0, '无促销', 0, 0,
              DATE '0001-01-01', DATE '9999-12-31', '促销汇总', 1);

      -- Three finite campaigns per calendar month. IDs and FULL validity
      -- windows depend only on the month/type, never on the requested range.
      -- Insert only: append must not change any historical campaign.
      -- IDs 1000..360963 fit the existing NUMBER(6) and never collide with 999.
      MERGE INTO promotions p
      USING (
         SELECT 1000 + ((EXTRACT(YEAR FROM m.month_start) - 1) * 12
                       + EXTRACT(MONTH FROM m.month_start) - 1) * 3
                       + k.kind - 1 promo_id,
                TO_CHAR(m.month_start, 'YYYYMM') ||
                   CASE k.kind WHEN 1 THEN '会员优惠'
                               WHEN 2 THEN '线上优惠' ELSE '月末优惠' END promo_name,
                CASE k.kind WHEN 1 THEN '会员优惠'
                            WHEN 2 THEN '线上优惠' ELSE '月末优惠' END promo_subcategory,
                k.kind promo_subcategory_id,
                CASE k.kind WHEN 3 THEN '合作渠道促销' ELSE '直营促销' END promo_category,
                CASE k.kind WHEN 3 THEN 2 ELSE 1 END promo_category_id,
                m.month_start + CASE k.kind WHEN 1 THEN 0 WHEN 2 THEN 7 ELSE 17 END promo_begin_date,
                CASE k.kind WHEN 1 THEN m.month_start + 13
                            WHEN 2 THEN m.month_start + 20
                            ELSE LAST_DAY(m.month_start) END promo_end_date
           FROM (SELECT ADD_MONTHS(v_first_month, LEVEL - 1) month_start
                   FROM dual CONNECT BY LEVEL <= v_month_count) m
          CROSS JOIN (SELECT LEVEL kind FROM dual CONNECT BY LEVEL <= 3) k
      ) s
         ON (p.promo_id = s.promo_id)
      WHEN NOT MATCHED THEN INSERT (
         promo_id, promo_name, promo_subcategory, promo_subcategory_id,
         promo_category, promo_category_id, promo_cost,
         promo_begin_date, promo_end_date, promo_total, promo_total_id)
      VALUES (s.promo_id, s.promo_name, s.promo_subcategory, s.promo_subcategory_id,
              s.promo_category, s.promo_category_id,
              10000 + MOD(s.promo_id * 137, 90001),
              s.promo_begin_date, s.promo_end_date, '促销汇总', 1);
   END ensure_promotions;

   PROCEDURE validate_range(p_start_date IN DATE, p_end_date IN DATE) IS
      v_invalid NUMBER;
   BEGIN
      check_range(p_start_date, p_end_date);

      SELECT COUNT(*) INTO v_invalid FROM promotions
       WHERE promo_begin_date IS NULL OR promo_end_date IS NULL
          OR promo_begin_date > promo_end_date;
      IF v_invalid > 0 THEN
         RAISE_APPLICATION_ERROR(-20981, '促销有效期为空或起止倒置。');
      END IF;

      -- LEFT JOIN also detects missing dimension rows while load-time FKs
      -- are disabled. The no-promotion sentinel is deliberately NOT exempt.
      SELECT COUNT(*) INTO v_invalid
        FROM sales s LEFT JOIN promotions p ON p.promo_id = s.promo_id
       WHERE s.time_id BETWEEN p_start_date AND p_end_date
         AND (p.promo_id IS NULL OR s.time_id < p.promo_begin_date
                                OR s.time_id > p.promo_end_date);
      IF v_invalid > 0 THEN
         RAISE_APPLICATION_ERROR(-20982, 'SALES 关联缺失或日期超出促销有效期，行数：' || v_invalid);
      END IF;

      SELECT COUNT(*) INTO v_invalid
        FROM costs c LEFT JOIN promotions p ON p.promo_id = c.promo_id
       WHERE c.time_id BETWEEN p_start_date AND p_end_date
         AND (p.promo_id IS NULL OR c.time_id < p.promo_begin_date
                                OR c.time_id > p.promo_end_date);
      IF v_invalid > 0 THEN
         RAISE_APPLICATION_ERROR(-20983, 'COSTS 关联缺失或日期超出促销有效期，行数：' || v_invalid);
      END IF;

      SELECT COUNT(DISTINCT time_id) INTO v_invalid FROM times
       WHERE time_id BETWEEN p_start_date AND p_end_date;
      IF v_invalid != p_end_date - p_start_date + 1 THEN
         RAISE_APPLICATION_ERROR(-20984, '生成范围内 TIMES 日期不完整。');
      END IF;

      -- Do not silently lose sales by filtering invalid randomly-picked IDs.
      -- Assert the exact daily quota (also handles leap years / partial years).
      SELECT COUNT(*) INTO v_invalid
        FROM times t
        LEFT JOIN (SELECT time_id, COUNT(*) row_count FROM sales
                    WHERE time_id BETWEEN p_start_date AND p_end_date
                    GROUP BY time_id) s ON s.time_id = t.time_id
       WHERE t.time_id BETWEEN p_start_date AND p_end_date
         AND NVL(s.row_count, 0) !=
             FLOOR((t.time_id - TRUNC(t.time_id, 'YYYY') + 1) * c_rows_per_year /
                   (ADD_MONTHS(TRUNC(t.time_id, 'YYYY'), 12) - TRUNC(t.time_id, 'YYYY'))) -
             FLOOR((t.time_id - TRUNC(t.time_id, 'YYYY')) * c_rows_per_year /
                   (ADD_MONTHS(TRUNC(t.time_id, 'YYYY'), 12) - TRUNC(t.time_id, 'YYYY')));
      IF v_invalid > 0 THEN
         RAISE_APPLICATION_ERROR(-20985, '每日销售行数与生成目标不符，异常天数：' || v_invalid);
      END IF;
   END validate_range;

   PROCEDURE generate_facts(
      p_start_date IN DATE, p_end_date IN DATE,
      p_sales_rows OUT NUMBER, p_cost_rows OUT NUMBER) IS
      v_product_count PLS_INTEGER;
      v_customer_count PLS_INTEGER;
      v_channel_count PLS_INTEGER;
   BEGIN
      check_range(p_start_date, p_end_date);
      ensure_promotions(p_start_date, p_end_date);

      SELECT COUNT(*) INTO v_product_count FROM products;
      SELECT COUNT(*) INTO v_customer_count FROM customers;
      SELECT COUNT(*) INTO v_channel_count FROM channels;
      IF v_product_count = 0 OR v_customer_count = 0 OR v_channel_count = 0 THEN
         RAISE_APPLICATION_ERROR(-20986, '生成销售数据所需的维度表不能为空。');
      END IF;

      INSERT INTO sales (prod_id, cust_id, time_id, channel_id, promo_id, quantity_sold, amount_sold)
         WITH daily_target AS (
            SELECT /*+ materialize */ time_id,
                   FLOOR((time_id - TRUNC(time_id, 'YYYY') + 1) * c_rows_per_year /
                         (ADD_MONTHS(TRUNC(time_id, 'YYYY'), 12) - TRUNC(time_id, 'YYYY'))) -
                   FLOOR((time_id - TRUNC(time_id, 'YYYY')) * c_rows_per_year /
                         (ADD_MONTHS(TRUNC(time_id, 'YYYY'), 12) - TRUNC(time_id, 'YYYY'))) row_count
              FROM times WHERE time_id BETWEEN p_start_date AND p_end_date
         ), daily_promos AS (
            SELECT /*+ materialize */ d.time_id, p.promo_id,
                   ROW_NUMBER() OVER (PARTITION BY d.time_id ORDER BY p.promo_id) promo_rn
              FROM daily_target d
              JOIN promotions p ON d.time_id BETWEEN p.promo_begin_date AND p.promo_end_date
         ), daily_promo_counts AS (
            SELECT /*+ materialize */ time_id, COUNT(*) promo_count
              FROM daily_promos GROUP BY time_id
         ), sale_keys AS (
            -- Build the small per-day candidate set BEFORE expanding sales.
            SELECT /*+ materialize leading(d pc n) */ d.time_id, n.sale_no, pc.promo_count,
                   TO_CHAR(d.time_id, 'YYYYMMDD') || ':' || TO_CHAR(n.sale_no) || ':' || TO_CHAR(c_seed) row_key
              FROM daily_target d
              JOIN daily_promo_counts pc ON pc.time_id = d.time_id
              JOIN (SELECT LEVEL sale_no FROM dual CONNECT BY LEVEL <= 600) n
                ON n.sale_no <= d.row_count
         ), randomized_sales AS (
            SELECT /*+ materialize */ time_id, sale_no,
                   MOD(ORA_HASH(row_key || ':P', 999999), v_product_count) + 1 product_rn,
                   MOD(ORA_HASH(row_key || ':C', 999999), v_customer_count) + 1 customer_rn,
                   MOD(ORA_HASH(row_key || ':H', 999999), v_channel_count) + 1 channel_rn,
                   MOD(ORA_HASH(row_key || ':R', 999999), promo_count) + 1 promo_rn,
                   MOD(ORA_HASH(row_key || ':Q', 999999), 5) + 1 quantity_sold,
                   70 + MOD(ORA_HASH(row_key || ':D', 999999), 26) discount_percent
              FROM sale_keys
         ), product_list AS (
            SELECT /*+ materialize */ prod_id, prod_list_price,
                   ROW_NUMBER() OVER (ORDER BY prod_id) rn FROM products
         ), customer_list AS (
            SELECT /*+ materialize */ cust_id, ROW_NUMBER() OVER (ORDER BY cust_id) rn FROM customers
         ), channel_list AS (
            SELECT /*+ materialize */ channel_id, ROW_NUMBER() OVER (ORDER BY channel_id) rn FROM channels
         )
         SELECT /*+ leading(r) use_hash(p c ch pr) */
                p.prod_id, c.cust_id, r.time_id, ch.channel_id, pr.promo_id,
                r.quantity_sold,
                ROUND(p.prod_list_price * r.quantity_sold *
                      CASE WHEN pr.promo_id = 999 THEN 100 ELSE r.discount_percent END / 100, 2)
           FROM randomized_sales r
           JOIN product_list p ON p.rn = r.product_rn
           JOIN customer_list c ON c.rn = r.customer_rn
           JOIN channel_list ch ON ch.rn = r.channel_rn
           JOIN daily_promos pr ON pr.time_id = r.time_id AND pr.promo_rn = r.promo_rn;
      p_sales_rows := SQL%ROWCOUNT;

      INSERT INTO costs (prod_id, time_id, promo_id, channel_id, unit_cost, unit_price)
         SELECT s.prod_id, s.time_id, s.promo_id, s.channel_id,
                ROUND(p.prod_min_price * 0.72, 2), p.prod_list_price
           FROM (SELECT DISTINCT prod_id, time_id, promo_id, channel_id FROM sales
                  WHERE time_id BETWEEN p_start_date AND p_end_date) s
           JOIN products p ON p.prod_id = s.prod_id;
      p_cost_rows := SQL%ROWCOUNT;

      -- No COMMIT here: callers validate before refreshing MVs / committing,
      -- and roll back promotions, times and facts together on failure.
      validate_range(p_start_date, p_end_date);
   END generate_facts;
END sh_data_generation;
/

SHOW ERRORS PACKAGE sh_data_generation
SHOW ERRORS PACKAGE BODY sh_data_generation

-- SQLcl may only warn on a compiled INVALID package; fail installation early.
DECLARE
   v_errors NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_errors FROM all_errors
    WHERE owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
      AND name = 'SH_DATA_GENERATION' AND type IN ('PACKAGE', 'PACKAGE BODY')
      AND attribute = 'ERROR';
   IF v_errors > 0 THEN
      RAISE_APPLICATION_ERROR(-20987, 'SH_DATA_GENERATION 编译失败，请检查以上错误。');
   END IF;
END;
/
