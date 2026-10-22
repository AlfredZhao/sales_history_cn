rem
rem 中文化维度并按安装参数完整生成 SH 事实数据。
rem 本脚本由 sh_populate.sql 调用，依赖 SQLcl 中的 generation_* 定义。
rem

SET DEFINE ON
SET SERVEROUTPUT ON

DECLARE
   v_mode          VARCHAR2(10) := UPPER(TRIM('&generation_mode'));
   v_years         PLS_INTEGER := TO_NUMBER('&generation_years');
   v_start_text    VARCHAR2(30) := TRIM('&generation_start');
   v_end_text      VARCHAR2(30) := TRIM('&generation_end');
   v_requested_start DATE;
   v_requested_end   DATE;
   v_rows            NUMBER;
   v_cost_rows       NUMBER;
BEGIN
   IF v_mode = 'RECENT' THEN
      IF v_years < 0 OR v_years > 100 THEN
         RAISE_APPLICATION_ERROR(-20990, '完整自然年数必须在 0 到 100 之间。');
      END IF;
      v_requested_start := ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -12 * v_years);
      v_requested_end   := TRUNC(SYSDATE);
   ELSIF v_mode = 'RANGE' THEN
      IF NOT REGEXP_LIKE(v_start_text, '^\d{4}-\d{2}-\d{2}$')
         OR NOT REGEXP_LIKE(v_end_text, '^\d{4}-\d{2}-\d{2}$') THEN
         RAISE_APPLICATION_ERROR(-20991, 'RANGE 模式必须填写 YYYY-MM-DD 格式的起始和结束日期。');
      END IF;
      v_requested_start := TO_DATE(v_start_text, 'FXYYYY-MM-DD');
      v_requested_end   := TO_DATE(v_end_text, 'FXYYYY-MM-DD');
      IF v_requested_start > v_requested_end THEN
         RAISE_APPLICATION_ERROR(-20992, '起始日期不能晚于结束日期。');
      END IF;
   ELSE
      RAISE_APPLICATION_ERROR(-20993, '生成模式只能是 RECENT 或 RANGE。');
   END IF;

   DBMS_OUTPUT.PUT_LINE('请求范围：' || TO_CHAR(v_requested_start, 'YYYY-MM-DD') || ' 至 ' || TO_CHAR(v_requested_end, 'YYYY-MM-DD'));

   -- TIMES is generated from scratch for the complete requested range.
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
              CONNECT BY LEVEL <= v_requested_end - v_requested_start + 1) requested_dates;

   UPDATE times
      SET day_name = CASE TRUNC(time_id) - TRUNC(time_id, 'IW')
                        WHEN 0 THEN '星期一' WHEN 1 THEN '星期二' WHEN 2 THEN '星期三'
                        WHEN 3 THEN '星期四' WHEN 4 THEN '星期五' WHEN 5 THEN '星期六' ELSE '星期日' END,
          day_number_in_week = TRUNC(time_id) - TRUNC(time_id, 'IW') + 1,
          calendar_week_number = TRUNC((time_id - TRUNC(TRUNC(time_id, 'YYYY'), 'IW')) / 7) + 1,
          fiscal_week_number = TRUNC((time_id - TRUNC(TRUNC(time_id, 'YYYY'), 'IW')) / 7) + 1,
          week_ending_day = TRUNC(time_id, 'IW') + 6,
          week_ending_day_id = TO_NUMBER(TO_CHAR(TRUNC(time_id, 'IW') + 6, 'YYYYMMDD')),
          calendar_month_desc = TO_CHAR(time_id, 'YYYY') || '年' || TO_CHAR(time_id, 'MM') || '月',
          fiscal_month_desc = TO_CHAR(time_id, 'YYYY') || '年' || TO_CHAR(time_id, 'MM') || '月',
          calendar_month_name = TO_CHAR(time_id, 'MM') || '月',
          fiscal_month_name = TO_CHAR(time_id, 'MM') || '月',
          calendar_quarter_desc = TO_CHAR(time_id, 'YYYY') || '年Q' || TO_CHAR(time_id, 'Q'),
          fiscal_quarter_desc = TO_CHAR(time_id, 'YYYY') || '年Q' || TO_CHAR(time_id, 'Q');

   UPDATE countries SET country_total = '全球汇总';
   UPDATE customers
      SET cust_first_name = CASE MOD(cust_id, 8) WHEN 0 THEN '伟' WHEN 1 THEN '芳' WHEN 2 THEN '强' WHEN 3 THEN '娜' WHEN 4 THEN '磊' WHEN 5 THEN '敏' WHEN 6 THEN '军' ELSE '静' END,
          cust_last_name = CASE MOD(cust_id, 10) WHEN 0 THEN '王' WHEN 1 THEN '李' WHEN 2 THEN '张' WHEN 3 THEN '刘' WHEN 4 THEN '陈' WHEN 5 THEN '杨' WHEN 6 THEN '赵' WHEN 7 THEN '黄' WHEN 8 THEN '周' ELSE '吴' END,
          cust_marital_status = CASE MOD(cust_id, 3) WHEN 0 THEN '已婚' WHEN 1 THEN '未婚' ELSE '其他' END,
          cust_street_address = CASE MOD(cust_id, 6) WHEN 0 THEN '朝阳区' WHEN 1 THEN '浦东新区' WHEN 2 THEN '天河区' WHEN 3 THEN '西湖区' WHEN 4 THEN '武侯区' ELSE '渝中区' END || TO_CHAR(MOD(cust_id, 999) + 1) || '号',
          cust_postal_code = TO_CHAR(100000 + MOD(cust_id, 900000)),
          cust_city = CASE MOD(cust_id, 6) WHEN 0 THEN '北京' WHEN 1 THEN '上海' WHEN 2 THEN '广州' WHEN 3 THEN '杭州' WHEN 4 THEN '成都' ELSE '重庆' END,
          cust_city_id = 100000 + MOD(cust_id, 6),
          cust_state_province = CASE MOD(cust_id, 6) WHEN 0 THEN '北京市' WHEN 1 THEN '上海市' WHEN 2 THEN '广东省' WHEN 3 THEN '浙江省' WHEN 4 THEN '四川省' ELSE '重庆市' END,
          cust_state_province_id = 1000 + MOD(cust_id, 6), country_id = 52771,
          cust_main_phone_number = '1' || TO_CHAR(3000000000 + MOD(cust_id, 6999999999), 'FM9999999999'),
          cust_income_level = CASE MOD(cust_id, 4) WHEN 0 THEN '10万元以下' WHEN 1 THEN '10万至20万元' WHEN 2 THEN '20万至50万元' ELSE '50万元以上' END,
          cust_email = 'customer' || cust_id || '@example.cn', cust_total = '客户汇总';
   UPDATE products
      SET prod_unit_of_measure = '件', prod_pack_size = '标准包装', prod_status = '在售', prod_total = '产品汇总';
   UPDATE supplementary_demographics
      SET education = CASE MOD(cust_id, 4) WHEN 0 THEN '大学本科' WHEN 1 THEN '硕士研究生' WHEN 2 THEN '高中及以下' ELSE '大专' END,
          occupation = CASE MOD(cust_id, 5) WHEN 0 THEN '企业职员' WHEN 1 THEN '教师' WHEN 2 THEN '工程师' WHEN 3 THEN '个体经营' ELSE '自由职业' END,
          household_size = TO_CHAR(MOD(cust_id, 5) + 1) || '人家庭',
          comments = '中国本土模拟客户';

   sh_data_generation.generate_facts(
      v_requested_start, v_requested_end, v_rows, v_cost_rows);
   DBMS_OUTPUT.PUT_LINE('完整生成范围：' || TO_CHAR(v_requested_start, 'YYYY-MM-DD') || ' 至 ' || TO_CHAR(v_requested_end, 'YYYY-MM-DD'));
   DBMS_OUTPUT.PUT_LINE('生成 SALES 行数：' || TO_CHAR(v_rows) || '；随机种子：' || sh_data_generation.c_seed);
   DBMS_OUTPUT.PUT_LINE('生成 COSTS 行数：' || TO_CHAR(v_cost_rows) || '（按产品、日期、促销和渠道去重）');

   DBMS_MVIEW.REFRESH('CAL_MONTH_SALES_MV,FWEEK_PSCAT_SALES_MV', 'C');
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
END;
/

SET SERVEROUTPUT OFF
