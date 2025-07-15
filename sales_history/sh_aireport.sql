rem *************************** AI Report Demo

Prompt ******  CREATE OR REPLACE VIEW BI_SALES_VIEW ...
CREATE OR REPLACE VIEW BI_SALES_VIEW AS
SELECT 
--时间维度
  t.time_id,
  t.day_name,
  t.day_number_in_week,
  t.calendar_month_desc,
  t.calendar_quarter_desc,
  t.calendar_year,
--销售信息
  s.amount_sold,
  s.quantity_sold,
  COALESCE(cs.unit_cost * s.quantity_sold, 0) AS total_cost,
  s.amount_sold - COALESCE(cs.unit_cost * s.quantity_sold, 0) AS profit,
--顾客信息
  c.cust_id,
  c.cust_first_name,
  c.cust_last_name,
  c.cust_gender,
  c.cust_year_of_birth,
  c.cust_marital_status,
  c.cust_email,
  c.cust_income_level,
  c.cust_credit_limit,
  c.cust_street_address,
  c.cust_postal_code,
  c.cust_city,
  c.cust_state_province,
  c.cust_main_phone_number,
--国家信息
  co.country_id,
  co.country_name,
  co.country_iso_code,
  co.country_subregion,
  co.country_region,
--产品信息
  p.prod_id,
  p.prod_name,
  p.prod_desc,
  p.prod_subcategory,
  p.prod_subcategory_desc,
  p.prod_category,
  p.prod_category_desc,
  p.prod_weight_class,
  p.prod_unit_of_measure,
  p.prod_pack_size,
  p.prod_status,
  p.prod_list_price,
  p.prod_min_price,
  p.supplier_id,
--渠道和促销信息
  ch.channel_id,
  ch.channel_desc,
  ch.channel_class,
  pr.promo_id,
  pr.promo_name,
  pr.promo_subcategory,
  pr.promo_category,
  pr.promo_cost,
  pr.promo_begin_date,
  pr.promo_end_date
FROM 
  sales s
JOIN customers c         ON s.cust_id = c.cust_id
JOIN countries co        ON c.country_id = co.country_id
JOIN products p          ON s.prod_id = p.prod_id
JOIN times t             ON s.time_id = t.time_id
JOIN channels ch         ON s.channel_id = ch.channel_id
LEFT JOIN promotions pr  ON s.promo_id = pr.promo_id
LEFT JOIN costs cs 
       ON s.prod_id = cs.prod_id 
      AND s.time_id = cs.time_id 
      AND s.channel_id = cs.channel_id 
      AND s.promo_id = cs.promo_id;

