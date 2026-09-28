rem
rem Extend an existing Chinese SH sample schema with deterministic fact data.
rem Run this script while connected as SH, from the sales_history directory.
rem It never regenerates existing dates: the start date is MAX(TIMES.TIME_ID) + 1.
rem

SET VERIFY OFF
SET DEFINE ON
SET SERVEROUTPUT ON

COLUMN append_end_default NEW_VALUE append_end_default NOPRINT
SELECT TO_CHAR(TRUNC(SYSDATE), 'YYYY-MM-DD') AS append_end_default FROM dual;

PROMPT
PROMPT 将从当前 TIMES 最大日期的下一天开始追加；已有日期不会被重建。
ACCEPT append_end CHAR PROMPT '追加目标结束日期 (YYYY-MM-DD) [&append_end_default]: ' DEFAULT '&append_end_default'

-- 该表必须在下面匿名块编译前已存在：匿名 PL/SQL 块中的静态 SQL
-- 会在执行前解析，不能依赖同一块内稍后执行的动态 CREATE TABLE。
DECLARE
BEGIN
   IF USER <> 'SH' THEN
      RAISE_APPLICATION_ERROR(-20994, '请以 SH 用户连接后执行 sh_append.sql。');
   END IF;

   BEGIN
      EXECUTE IMMEDIATE q'[
         CREATE TABLE sh_generation_log (
            run_id          RAW(16)      NOT NULL,
            run_type        VARCHAR2(20) NOT NULL,
            status          VARCHAR2(20) NOT NULL,
            requested_start DATE,
            requested_end   DATE,
            sales_rows      NUMBER,
            costs_rows      NUMBER,
            started_at      TIMESTAMP    NOT NULL,
            finished_at     TIMESTAMP,
            error_message   VARCHAR2(4000),
            CONSTRAINT sh_generation_log_pk PRIMARY KEY (run_id)
         )]';
   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE != -955 THEN
            RAISE;
         END IF;
   END;
END;
/

DECLARE
   c_rows_per_year CONSTANT PLS_INTEGER := 200000;
   c_seed          CONSTANT PLS_INTEGER := 20260909;
   v_end_text      VARCHAR2(30) := TRIM('&append_end');
   v_requested_start DATE;
   v_requested_end   DATE;
   v_current_start   DATE;
   v_current_end     DATE;
   v_time_count      NUMBER;
   v_sales_day_count NUMBER;
   v_sales_max       DATE;
   v_costs_day_count NUMBER;
   v_costs_max       DATE;
   v_rows            NUMBER := 0;
   v_cost_rows       NUMBER := 0;
   v_product_count   PLS_INTEGER;
   v_customer_count  PLS_INTEGER;
   v_channel_count   PLS_INTEGER;
   v_promo_count     PLS_INTEGER;
   v_run_id          RAW(16) := SYS_GUID();
   v_error_message   VARCHAR2(4000);

   PROCEDURE update_run(
      p_status      IN VARCHAR2,
      p_start_date  IN DATE,
      p_end_date    IN DATE,
      p_sales_rows  IN NUMBER,
      p_cost_rows   IN NUMBER,
      p_error_text  IN VARCHAR2 DEFAULT NULL
   ) IS
   BEGIN
      UPDATE sh_generation_log
         SET status = p_status,
             requested_start = p_start_date,
             requested_end = p_end_date,
             sales_rows = p_sales_rows,
             costs_rows = p_cost_rows,
             finished_at = SYSTIMESTAMP,
             error_message = p_error_text
       WHERE run_id = v_run_id;
      COMMIT;
   END update_run;
BEGIN
   IF NOT REGEXP_LIKE(v_end_text, '^\d{4}-\d{2}-\d{2}$') THEN
      RAISE_APPLICATION_ERROR(-20995, '目标结束日期必须使用 YYYY-MM-DD 格式。');
   END IF;
   v_requested_end := TO_DATE(v_end_text, 'FXYYYY-MM-DD');

   INSERT INTO sh_generation_log (run_id, run_type, status, started_at)
   VALUES (v_run_id, 'APPEND', 'RUNNING', SYSTIMESTAMP);
   COMMIT;

   BEGIN
      EXECUTE IMMEDIATE 'LOCK TABLE times IN EXCLUSIVE MODE NOWAIT';
   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE = -54 THEN
            RAISE_APPLICATION_ERROR(-20996, 'TIMES 正被其他会话修改；请稍后重试追加。');
         END IF;
         RAISE;
   END;

   SELECT MIN(time_id), MAX(time_id), COUNT(*)
     INTO v_current_start, v_current_end, v_time_count
     FROM times;

   IF v_current_end IS NULL THEN
      RAISE_APPLICATION_ERROR(-20997, 'TIMES 为空。请先通过 sh_install.sql 初始化 SH 模式。');
   END IF;

   IF v_time_count != v_current_end - v_current_start + 1 THEN
      RAISE_APPLICATION_ERROR(-20998, 'TIMES 日期范围不连续，拒绝追加。请先修复缺失日期。');
   END IF;

   SELECT COUNT(DISTINCT time_id), MAX(time_id)
     INTO v_sales_day_count, v_sales_max
     FROM sales;
   SELECT COUNT(DISTINCT time_id), MAX(time_id)
     INTO v_costs_day_count, v_costs_max
     FROM costs;
   IF v_sales_day_count != v_time_count OR v_sales_max != v_current_end
      OR v_costs_day_count != v_time_count OR v_costs_max != v_current_end THEN
      RAISE_APPLICATION_ERROR(-21000,
         'SALES、COSTS 与 TIMES 的日期覆盖范围不一致，拒绝追加。请先修复事实数据。');
   END IF;

   IF v_requested_end <= v_current_end THEN
      update_run('SKIPPED', v_current_end + 1, v_requested_end, 0, 0,
                 '目标结束日期未晚于当前最大日期。');
      DBMS_OUTPUT.PUT_LINE('无需追加：当前最大日期为 ' || TO_CHAR(v_current_end, 'YYYY-MM-DD') || '。');
   ELSE
      v_requested_start := v_current_end + 1;
      UPDATE sh_generation_log
         SET requested_start = v_requested_start,
             requested_end = v_requested_end
       WHERE run_id = v_run_id;

      SELECT COUNT(*) INTO v_product_count  FROM products;
      SELECT COUNT(*) INTO v_customer_count FROM customers;
      SELECT COUNT(*) INTO v_channel_count  FROM channels;
      SELECT COUNT(*) INTO v_promo_count    FROM promotions;
      IF v_product_count = 0 OR v_customer_count = 0
         OR v_channel_count = 0 OR v_promo_count = 0 THEN
         RAISE_APPLICATION_ERROR(-20999, '生成销售数据所需的维度表不能为空。');
      END IF;

   INSERT INTO times (
         time_id, day_name, day_number_in_week, day_number_in_month,
         calendar_week_number, fiscal_week_number, week_ending_day, week_ending_day_id,
         calendar_month_number, fiscal_month_number, calendar_month_desc, calendar_month_id,
         fiscal_month_desc, fiscal_month_id, days_in_cal_month, days_in_fis_month,
         end_of_cal_month, end_of_fis_month, calendar_month_name, fiscal_month_name,
         calendar_quarter_desc, calendar_quarter_id, fiscal_quarter_desc, fiscal_quarter_id,
         days_in_cal_quarter, days_in_fis_quarter, end_of_cal_quarter, end_of_fis_quarter,
         calendar_quarter_number, fiscal_quarter_number, calendar_year, calendar_year_id,
         fiscal_year, fiscal_year_id, days_in_cal_year, days_in_fis_year,
         end_of_cal_year, end_of_fis_year)
      SELECT d,
             CASE TRUNC(d) - TRUNC(d, 'IW')
               WHEN 0 THEN '星期一' WHEN 1 THEN '星期二' WHEN 2 THEN '星期三'
               WHEN 3 THEN '星期四' WHEN 4 THEN '星期五' WHEN 5 THEN '星期六' ELSE '星期日' END,
             TRUNC(d) - TRUNC(d, 'IW') + 1, EXTRACT(DAY FROM d),
             TRUNC((d - TRUNC(TRUNC(d, 'YYYY'), 'IW')) / 7) + 1,
             TRUNC((d - TRUNC(TRUNC(d, 'YYYY'), 'IW')) / 7) + 1,
             TRUNC(d, 'IW') + 6, TO_NUMBER(TO_CHAR(TRUNC(d, 'IW') + 6, 'YYYYMMDD')),
             EXTRACT(MONTH FROM d), EXTRACT(MONTH FROM d),
             TO_CHAR(d, 'YYYY') || '年' || TO_CHAR(d, 'MM') || '月', TO_NUMBER(TO_CHAR(d, 'YYYYMM')),
             TO_CHAR(d, 'YYYY') || '年' || TO_CHAR(d, 'MM') || '月', TO_NUMBER(TO_CHAR(d, 'YYYYMM')),
             LAST_DAY(d) - TRUNC(d, 'MM') + 1, LAST_DAY(d) - TRUNC(d, 'MM') + 1,
             LAST_DAY(d), LAST_DAY(d), TO_CHAR(d, 'MM') || '月', TO_CHAR(d, 'MM') || '月',
             TO_CHAR(d, 'YYYY') || '年Q' || TO_CHAR(d, 'Q'), TO_NUMBER(TO_CHAR(d, 'YYYY') || TO_CHAR(d, 'Q')),
             TO_CHAR(d, 'YYYY') || '年Q' || TO_CHAR(d, 'Q'), TO_NUMBER(TO_CHAR(d, 'YYYY') || TO_CHAR(d, 'Q')),
             LAST_DAY(ADD_MONTHS(TRUNC(d, 'Q'), 2)) - TRUNC(d, 'Q') + 1,
             LAST_DAY(ADD_MONTHS(TRUNC(d, 'Q'), 2)) - TRUNC(d, 'Q') + 1,
             LAST_DAY(ADD_MONTHS(TRUNC(d, 'Q'), 2)), LAST_DAY(ADD_MONTHS(TRUNC(d, 'Q'), 2)),
             TO_NUMBER(TO_CHAR(d, 'Q')), TO_NUMBER(TO_CHAR(d, 'Q')),
             EXTRACT(YEAR FROM d), EXTRACT(YEAR FROM d), EXTRACT(YEAR FROM d), EXTRACT(YEAR FROM d),
             ADD_MONTHS(TRUNC(d, 'YYYY'), 12) - TRUNC(d, 'YYYY'),
             ADD_MONTHS(TRUNC(d, 'YYYY'), 12) - TRUNC(d, 'YYYY'),
             ADD_MONTHS(TRUNC(d, 'YYYY'), 12) - 1, ADD_MONTHS(TRUNC(d, 'YYYY'), 12) - 1
        FROM (SELECT v_requested_start + LEVEL - 1 d
                FROM dual
              CONNECT BY LEVEL <= v_requested_end - v_requested_start + 1);

   INSERT INTO sales (prod_id, cust_id, time_id, channel_id, promo_id, quantity_sold, amount_sold)
      WITH daily_target AS (
         SELECT /*+ materialize */ time_id,
                FLOOR((time_id - TRUNC(time_id, 'YYYY') + 1) * c_rows_per_year /
                      (ADD_MONTHS(TRUNC(time_id, 'YYYY'), 12) - TRUNC(time_id, 'YYYY'))) -
                FLOOR((time_id - TRUNC(time_id, 'YYYY')) * c_rows_per_year /
                      (ADD_MONTHS(TRUNC(time_id, 'YYYY'), 12) - TRUNC(time_id, 'YYYY'))) row_count
           FROM times
          WHERE time_id BETWEEN v_requested_start AND v_requested_end
      ), sale_keys AS (
         SELECT /*+ materialize leading(d n) */
                d.time_id, n.sale_no,
                TO_CHAR(d.time_id, 'YYYYMMDD') || ':' || TO_CHAR(n.sale_no) || ':' || TO_CHAR(c_seed) row_key
           FROM daily_target d
           JOIN (SELECT LEVEL sale_no FROM dual CONNECT BY LEVEL <= 600) n
             ON n.sale_no <= d.row_count
      ), randomized_sales AS (
         SELECT /*+ materialize */ time_id, sale_no,
                MOD(ORA_HASH(row_key || ':P', 999999), v_product_count) + 1 product_rn,
                MOD(ORA_HASH(row_key || ':C', 999999), v_customer_count) + 1 customer_rn,
                MOD(ORA_HASH(row_key || ':H', 999999), v_channel_count) + 1 channel_rn,
                MOD(ORA_HASH(row_key || ':R', 999999), v_promo_count) + 1 promo_rn,
                MOD(ORA_HASH(row_key || ':Q', 999999), 5) + 1 quantity_sold,
                70 + MOD(ORA_HASH(row_key || ':D', 999999), 26) discount_percent
           FROM sale_keys
      ), product_list AS (
         SELECT /*+ materialize */ prod_id, prod_list_price, ROW_NUMBER() OVER (ORDER BY prod_id) rn FROM products
      ), customer_list AS (
         SELECT /*+ materialize */ cust_id, ROW_NUMBER() OVER (ORDER BY cust_id) rn FROM customers
      ), channel_list AS (
         SELECT /*+ materialize */ channel_id, ROW_NUMBER() OVER (ORDER BY channel_id) rn FROM channels
      ), promo_list AS (
         SELECT /*+ materialize */ promo_id, ROW_NUMBER() OVER (ORDER BY promo_id) rn FROM promotions
      )
      SELECT /*+ leading(r) use_hash(p c ch pr) */
             p.prod_id, c.cust_id, r.time_id, ch.channel_id, pr.promo_id,
             r.quantity_sold,
             ROUND(p.prod_list_price * r.quantity_sold * r.discount_percent / 100, 2)
        FROM randomized_sales r
        JOIN product_list p  ON p.rn = r.product_rn
        JOIN customer_list c ON c.rn = r.customer_rn
        JOIN channel_list ch ON ch.rn = r.channel_rn
        JOIN promo_list pr   ON pr.rn = r.promo_rn;
   v_rows := SQL%ROWCOUNT;

   INSERT INTO costs (prod_id, time_id, promo_id, channel_id, unit_cost, unit_price)
      SELECT s.prod_id, s.time_id, s.promo_id, s.channel_id,
             ROUND(p.prod_min_price * 0.72, 2), p.prod_list_price
        FROM (SELECT DISTINCT prod_id, time_id, promo_id, channel_id
                FROM sales
               WHERE time_id BETWEEN v_requested_start AND v_requested_end) s
        JOIN products p ON p.prod_id = s.prod_id;
   v_cost_rows := SQL%ROWCOUNT;

   DBMS_MVIEW.REFRESH('CAL_MONTH_SALES_MV,FWEEK_PSCAT_SALES_MV', 'C');
   update_run('SUCCESS', v_requested_start, v_requested_end, v_rows, v_cost_rows);

   BEGIN
   DBMS_STATS.GATHER_TABLE_STATS(USER, 'TIMES', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE);
   DBMS_STATS.GATHER_TABLE_STATS(USER, 'SALES', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE);
   DBMS_STATS.GATHER_TABLE_STATS(USER, 'COSTS', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE);
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('数据已追加，但收集统计信息失败：' || SQLERRM);
   END;
   DBMS_OUTPUT.PUT_LINE('追加完成：' || TO_CHAR(v_requested_start, 'YYYY-MM-DD') || ' 至 ' || TO_CHAR(v_requested_end, 'YYYY-MM-DD'));
   DBMS_OUTPUT.PUT_LINE('新增 SALES 行数：' || TO_CHAR(v_rows) || '；随机种子：' || c_seed);
   DBMS_OUTPUT.PUT_LINE('新增 COSTS 行数：' || TO_CHAR(v_cost_rows) || '（按产品、日期、促销和渠道去重）');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      v_error_message := SUBSTR(SQLERRM, 1, 4000);
      BEGIN
         UPDATE sh_generation_log
            SET status = 'FAILED',
                finished_at = SYSTIMESTAMP,
                error_message = v_error_message
          WHERE run_id = v_run_id;
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      RAISE;
END;
/

SET SERVEROUTPUT OFF
