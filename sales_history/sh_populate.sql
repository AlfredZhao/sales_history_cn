rem
rem Copyright (c) 2023 Oracle
rem
rem Permission is hereby granted, free of charge, to any person obtaining a
rem copy of this software and associated documentation files (the "Software"),
rem to deal in the Software without restriction, including without limitation
rem the rights to use, copy, modify, merge, publish, distribute, sublicense,
rem and/or sell copies of the Software, and to permit persons to whom the
rem Software is furnished to do so, subject to the following conditions:
rem
rem The above copyright notice and this permission notice shall be included in
rem all copies or substantial portions rem of the Software.
rem
rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
rem IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
rem FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
rem THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
rem LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
rem OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
rem SOFTWARE.
rem
rem NAME
rem   sh_populate.sql - populates the SH (Sales History) tables with data
rem
rem DESCRIPTION
rem   This script populates the SH tables with rows of data
rem
rem SCHEMA VERSION
rem   21
rem
rem RELEASE DATE
rem   06-DEC-2022
rem
rem SUPPORTED with DB VERSIONS
rem   19c and higher
rem
rem MAJOR CHANGES IN THIS RELEASE
rem   new scripts for SH installation
rem
rem SCHEMA DEPENDENCIES AND REQUIREMENTS
rem   This script is called from the sh_install.sql script
rem
rem INSTALL INSTRUCTIONS
rem    Run the sh_install.sql script to call this script
rem
rem NOTES
rem 
rem
rem --------------------------------------------------------------------------

SET VERIFY OFF
SET DEFINE OFF
ALTER SESSION SET NLS_LANGUAGE=American;

rem *************************** Disabling table constraints

Prompt ******  Disabling table constraints for the load

ALTER TABLE sales
   MODIFY CONSTRAINT sales_promo_fk DISABLE NOVALIDATE;
ALTER TABLE sales
   MODIFY CONSTRAINT sales_customer_fk DISABLE NOVALIDATE;
ALTER TABLE sales
   MODIFY CONSTRAINT sales_product_fk DISABLE NOVALIDATE;
ALTER TABLE sales
   MODIFY CONSTRAINT sales_time_fk DISABLE NOVALIDATE;
ALTER TABLE sales
   MODIFY CONSTRAINT sales_channel_fk DISABLE NOVALIDATE;

ALTER TABLE customers
   MODIFY CONSTRAINT customers_country_fk DISABLE NOVALIDATE;

ALTER TABLE costs
   MODIFY CONSTRAINT costs_product_fk DISABLE NOVALIDATE;
ALTER TABLE costs
   MODIFY CONSTRAINT costs_time_fk DISABLE NOVALIDATE;
ALTER TABLE costs
   MODIFY CONSTRAINT costs_channel_fk DISABLE NOVALIDATE;
ALTER TABLE costs
   MODIFY CONSTRAINT costs_promo_fk DISABLE NOVALIDATE;

ALTER TABLE times
   MODIFY CONSTRAINT times_pk DISABLE NOVALIDATE;

ALTER TABLE channels
   MODIFY CONSTRAINT channels_pk DISABLE NOVALIDATE;

ALTER TABLE countries
   MODIFY CONSTRAINT countries_pk DISABLE NOVALIDATE;
   
ALTER TABLE promotions
   MODIFY CONSTRAINT promo_pk DISABLE NOVALIDATE;

ALTER TABLE products
   MODIFY CONSTRAINT products_pk DISABLE NOVALIDATE;

ALTER TABLE customers
   MODIFY CONSTRAINT customers_pk DISABLE NOVALIDATE;

rem *************************** insert data into the CHANNELS table

Prompt ******  Populating CHANNELS table ....

BEGIN
   INSERT INTO channels VALUES
      ( 3, '直销',     '直达渠道', 12, '渠道汇总', 1 );
   INSERT INTO channels VALUES
      ( 9, '电话销售', '直达渠道', 12, '渠道汇总', 1 );
   INSERT INTO channels VALUES
      ( 5, '目录销售', '间接渠道', 13, '渠道汇总', 1 );
   INSERT INTO channels VALUES
      ( 4, '网络销售', '间接渠道', 13, '渠道汇总', 1 );
   INSERT INTO channels VALUES
      ( 2, '合作伙伴', '其他渠道', 14, '渠道汇总', 1 );
END;
/


rem *************************** insert data into the COUNTRIES table

Prompt ******  Populating COUNTIRES table ....

BEGIN
   INSERT INTO countries VALUES
      (52790, 'US', '美国',        '北美洲',     52797, '美洲',      52801, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52776, 'DE', '德国',        '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52789, 'GB', '英国',        '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52784, 'NL', '荷兰',        '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52780, 'IE', '爱尔兰',      '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52777, 'DK', '丹麦',        '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52779, 'FR', '法国',        '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52778, 'ES', '西班牙',      '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52788, 'TR', '土耳其',      '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52786, 'PL', '波兰',        '东欧',       52795, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52775, 'BR', '巴西',        '南美洲',     52798, '美洲',      52801, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52773, 'AR', '阿根廷',      '南美洲',     52798, '美洲',      52801, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52783, 'MY', '马来西亚',    '亚洲',       52793, '亚洲',      52802, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52782, 'JP', '日本',        '亚洲',       52793, '亚洲',      52802, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52781, 'IN', '印度',        '亚洲',       52793, '亚洲',      52802, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52774, 'AU', '澳大利亚',    '澳大利亚',   52794, '大洋洲',    52805, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52785, 'NZ', '新西兰',      '澳大利亚',   52794, '大洋洲',    52805, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52791, 'ZA', '南非',        '非洲',       52792, '非洲',      52800, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52787, 'SA', '沙特阿拉伯',  '中东',       52796, '中东',      52804, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52772, 'CA', '加拿大',      '北美洲',     52797, '美洲',      52801, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52771, 'CN', '中国',        '亚洲',       52793, '亚洲',      52802, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52769, 'SG', '新加坡',      '亚洲',       52793, '亚洲',      52802, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52770, 'IT', '意大利',      '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52792, 'MX', '墨西哥',      '北美洲',     52797, '美洲',      52801, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52793, 'SE', '瑞典',        '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52794, 'CH', '瑞士',        '西欧',       52799, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52795, 'CL', '智利',        '南美洲',     52798, '美洲',      52801, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52796, 'TH', '泰国',        '亚洲',       52793, '亚洲',      52802, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52797, 'NG', '尼日利亚',    '非洲',       52792, '非洲',      52800, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52798, 'EG', '埃及',        '中东',       52796, '中东',      52804, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52799, 'ZW', '津巴布韦',    '非洲',       52792, '非洲',      52800, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52800, 'KW', '科威特',      '中东',       52796, '中东',      52804, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52801, 'IL', '以色列',      '中东',       52796, '中东',      52804, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52802, 'RO', '罗马尼亚',    '东欧',       52795, '欧洲',      52803, '世界汇总', 52806 );
   INSERT INTO countries VALUES
      (52803, 'HU', '匈牙利',      '东欧',       52795, '欧洲',      52803, '世界汇总', 52806 );
END;
/

rem *************************** insert data into the PRODUCTS table

Prompt ******  Populating PRODUCTS table ....
BEGIN
   INSERT INTO products VALUES 
      (14, '投球机与击球笼组合', '投球机与击球笼组合', '训练辅助与设备',
       2035, '训练辅助与设备', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 999.99, 999.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (21, '速度训练棒与训练计划', '速度训练棒与训练计划', '训练辅助与设备',
       2035, '训练辅助与设备', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 899.99, 899.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (22, 'MLB官方比赛棒球与展示盒', 'MLB官方比赛棒球与展示盒', '棒球',
       2031, '棒球', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 24.99, 24.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (46, '2个NFHS比赛级棒球', '2个NFHS比赛级棒球', '棒球',
       2031, '棒球', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 22.99, 22.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (47, '6加仑空球桶', '6加仑空球桶', '棒球',
       2031, '棒球', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 28.99, 28.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (127, '正品系列MIX木棒', '正品系列MIX木棒', '棒球棒',
       2036, '棒球棒', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 36.99, 36.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (128, '青少年系列枫木棒', '青少年系列枫木棒', '棒球棒',
       2036, '棒球棒', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 27.99, 27.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (129, '专业枫木棒', '专业枫木棒', '棒球棒',
       2036, '棒球棒', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 192.99, 192.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (130, '青少年专业枫木棒', '青少年专业枫木棒', '棒球棒',
       2036, '棒球棒', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 89.99, 89.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (19, '板球拍袋', '板球拍袋', '板球拍',
       2051, '板球拍', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 55.99, 55.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (23, '塑料板球拍', '塑料沙滩板球拍', '板球拍',
       2051, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 21.99, 21.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (28, '英格兰柳木板球拍', '英格兰柳木板球拍', '板球拍',
       2051, '板球拍', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 199.99, 199.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (30, '亚麻籽油', '板球拍亚麻籽油', '板球拍',
       2051, '板球拍', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 9.99, 9.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (31, '纤维胶带', '板球拍纤维胶带', '板球拍',
       2051, '板球拍', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 8.99, 8.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (40, '团队球衣', '西印度群岛队', '板球粉丝装备',
       2054, '板球粉丝装备', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (41, '团队球衣', '南非队', '板球粉丝装备',
       2054, '板球粉丝装备', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (42, '团队球衣', '新西兰板球队', '板球粉丝装备',
       2054, '板球粉丝装备', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (43, '团队球衣', '澳大利亚板球队', '板球粉丝装备',
       2054, '板球粉丝装备', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (44, '团队球衣', '印度板球队', '板球粉丝装备',
       2054, '板球粉丝装备', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (45, '团队球衣', '英格兰板球队', '板球粉丝装备',
       2054, '板球粉丝装备', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (48, '室内板球', '室内板球', '板球',
       2055, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 11.99, 11.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (113, '板球', '皮质板球', '板球',
       2055, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 22.99, 22.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (114, '训练板球', '训练用板球', '板球',
       2055, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 18.99, 18.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (115, '塑料板球', '塑料沙滩板球', '板球',
       2055, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 8.99, 8.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (116, '接球手头盔', '接球手头盔', '板球',
       2055, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 11.99, 11.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (117, '塑料板球门柱', '塑料沙滩板球门柱', '板球',
       2055, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 8.99, 8.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (118, '板球横木', '板球横木', '板球',
       2055, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 7.99, 7.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (119, '青少年板球横木', '青少年板球横木', '板球',
       2055, '板球', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 6.99, 6.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (120, '板球鸭舌帽', '板球鸭舌帽', '板球服装',
       2056, '板球服装', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 6.99, 6.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (121, '板球护裆', '板球护裆', '板球服装',
       2056, '板球服装', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 10.99, 10.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (122, '宽檐帽', '板球宽檐帽', '板球服装',
       2056, '板球服装', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 18.99, 18.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (123, '板球头盔', '板球头盔', '板球服装',
       2056, '板球服装', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 49.99, 49.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (124, '守门员手套', '守门员手套', '板球服装',
       2056, '板球服装', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 18.99, 18.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (125, '渔夫帽', '板球渔夫帽', '板球服装',
       2053, '板球服装', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 15.99, 15.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (126, '钉鞋', '板球钉鞋', '板球服装',
       2053, '板球服装', '板球', 205, '板球', 1, 'U', 'P', 1, 'STATUS', 28.99, 28.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (15, '右手石墨杆铁杆套装', '右手石墨杆铁杆套装', '铁杆与套装',
       2021, '铁杆与套装', '高尔夫', 202, '高尔夫', 1, 'U', 'P', 1, 'STATUS', 999.99, 999.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (18, '锂电高尔夫球车', '锂电高尔夫球车', '高尔夫球包与球车',
       2022, '高尔夫球包与球车', '高尔夫', 202, '高尔夫', 1, 'U', 'P', 1, 'STATUS', 1299.99, 1299.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (13, '便携式足球门', '便携式足球门', '足球',
       2044, '足球', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 899.99, 899.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (17, '官方足球门', '官方足球门', '足球',
       2041, '足球', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 1099.99, 1099.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (131, '4号足球', '4号青少年足球', '足球装备',
       2042, '足球装备', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 18.99, 18.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (132, '5号足球', '5号足球', '足球装备',
       2042, '足球装备', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 24.99, 24.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (133, '守门员手套', '守门员手套', '足球装备',
       2042, '足球装备', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 30.99, 30.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (134, '护胫', '护胫', '足球装备',
       2042, '足球装备', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 20.99, 20.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (135, '装备包', '装备包', '足球装备',
       2042, '足球装备', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 49.99, 49.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (136, '足球球衣', '足球球衣', '足球服装',
       2043, '足球服装', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 32.99, 32.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (137, '青少年足球鞋', '青少年足球鞋', '足球服装',
       2043, '足球服装', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 52.99, 52.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (138, '成人足球鞋', '成人足球鞋', '足球服装',
       2043, '足球服装', '足球', 204, '足球', 1, 'U', 'P', 1, 'STATUS', 69.99, 69.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (16, '声波核心石墨网球拍', '声波核心石墨网球拍', '网球拍',
       2011, '网球拍', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 299.99, 299.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (20, '比赛用签名网球拍', '比赛用签名网球拍', '网球拍',
       2012, '网球拍', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 599.99, 599.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (29, '限量版网球拍', '限量版网球拍', '网球拍',
       2012, '网球拍', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 499.99, 499.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (139, '重型毛毡网球3个装', '重型毛毡网球3个装', '网球',
       2014, '网球', '网球', 201, '网球', 4, 'U', 'P', 1, 'STATUS', 19.99, 19.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (140, '天然肠线网球线', '天然肠线网球线', '网球线',
       2014, '网球线', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 29.99, 29.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (141, '合成肠线网球线', '合成肠线网球线', '网球线',
       2014, '网球线', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 29.99, 29.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (142, '混合网球线', '混合网球线', '网球线',
       2014, '网球线', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 19.99, 19.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (143, '聚酯网球线', '聚酯网球线', '网球线',
       2014, '网球线', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 19.99, 19.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (144, '粘性网球拍柄带', '粘性网球拍柄带', '网球拍柄带',
       2014, '网球拍柄带', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 7.99, 7.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (145, '训练用网球', '训练用网球', '网球',
       2014, '网球', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 12.99, 12.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (146, '常规网球', '常规网球', '网球',
       2014, '网球', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 11.99, 11.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (147, '缓冲握把', '缓冲握把', '网球拍柄带',
       2013, '网球拍柄带', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 7.99, 7.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (148, '网球12个装', '网球12个装', '网球',
       2013, '网球', '网球', 201, '网球', 1, 'U', 'P', 1, 'STATUS', 20.99, 20.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (24, '耐力Coolcore半拉链上衣', '耐力Coolcore半拉链上衣', '棒球服装',
       2034, '棒球服装', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 45.99, 45.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (25, '五点式击球支架', '五点式击球支架', '击球支架',
       2033, '击球支架', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 112.99, 112.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (26, '专业款击球支架', '专业款击球支架', '击球支架',
       2033, '击球支架', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 149.99, 149.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (27, '24个合成棒球桶', '24个合成棒球桶', '棒球',
       2031, '棒球', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (32, '24个皮质棒球桶', '24个皮质棒球桶', '棒球',
       2031, '棒球', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 67.99, 67.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (33, '棒球人生帽', '棒球人生帽', '棒球服装',
       2034, '棒球服装', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (34, '11.5英寸青少年三条纹系列手套', '11.5英寸青少年三条纹系列手套', '手套与捕手手套',
       2032, '手套与捕手手套', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 39.99, 39.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (35, '捕手手套', '捕手手套', '手套与捕手手套',
       2032, '手套与捕手手套', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 49.99, 49.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (36, '12英寸高级系列手套', '12英寸高级系列手套', '手套与捕手手套',
       2032, '手套与捕手手套', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 44.99, 44.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (37, '12.75英寸高级系列手套', '12.75英寸高级系列手套', '手套与捕手手套',
       2032, '手套与捕手手套', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 54.99, 54.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (38, '11英寸青少年场大师手套', '11英寸青少年场大师手套', '手套与捕手手套',
       2032, '手套与捕手手套', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 29.99, 29.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
   INSERT INTO products VALUES 
      (39, '13英寸场大师系列手套', '13英寸场大师系列手套', '手套与捕手手套',
       2032, '手套与捕手手套', '棒球', 203, '棒球', 1, 'U', 'P', 1, 'STATUS', 34.99, 34.99,
       'TOTAL', 1, '', to_date('2019-01-01-00-00-00', 'YYYY-MM-DD-HH24-MI-SS'), '', 'A');
END;
/

COMMIT;

rem *************************** set loading parameters
SET LOAD BATCH_ROWS 10000 BATCHES_PER_COMMIT 1 DATE_FORMAT YYYY-MM-DD

rem *************************** insert data into the COSTS table

Prompt ******  Populating COSTS table ....
LOAD costs costs.csv

rem *************************** insert data into the CUSTOMERS table

Prompt ******  Populating CUSTOMERS table ....
LOAD customers customers.csv

rem *************************** insert data into the PROMOTIONS table

Prompt ******  Populating PROMOTIONS table ....
LOAD promotions promotions.csv

rem *************************** insert data into the SALES table

Prompt ******  Populating SALES table ....
LOAD sales sales.csv

rem *************************** insert data into the TIMES table

Prompt ******  Populating TIMES table ....
LOAD times times.csv

rem *************************** insert data into the SUPPLEMENTARY_DEMOGRAPHICS table

Prompt ******  Populating SUPPLEMENTARY_DEMOGRAPHICS table ....
LOAD supplementary_demographics supplementary_demographics.csv

rem *************************** Enabling table constraints

Prompt ******  Enabling table constraints

ALTER TABLE times
   MODIFY CONSTRAINT times_pk ENABLE NOVALIDATE;

ALTER TABLE channels
   MODIFY CONSTRAINT channels_pk ENABLE NOVALIDATE;

ALTER TABLE countries
   MODIFY CONSTRAINT countries_pk ENABLE NOVALIDATE;
   
ALTER TABLE promotions
   MODIFY CONSTRAINT promo_pk ENABLE NOVALIDATE;

ALTER TABLE products
   MODIFY CONSTRAINT products_pk ENABLE NOVALIDATE;

ALTER TABLE customers
   MODIFY CONSTRAINT customers_pk ENABLE NOVALIDATE;

ALTER TABLE sales
   MODIFY CONSTRAINT sales_promo_fk ENABLE NOVALIDATE;
ALTER TABLE sales
   MODIFY CONSTRAINT sales_customer_fk ENABLE NOVALIDATE;
ALTER TABLE sales
   MODIFY CONSTRAINT sales_product_fk ENABLE NOVALIDATE;
ALTER TABLE sales
   MODIFY CONSTRAINT sales_time_fk ENABLE NOVALIDATE;
ALTER TABLE sales
   MODIFY CONSTRAINT sales_channel_fk ENABLE NOVALIDATE;

ALTER TABLE customers
   MODIFY CONSTRAINT customers_country_fk ENABLE NOVALIDATE;

ALTER TABLE costs
   MODIFY CONSTRAINT costs_product_fk ENABLE NOVALIDATE;
ALTER TABLE costs
   MODIFY CONSTRAINT costs_time_fk ENABLE NOVALIDATE;
ALTER TABLE costs
   MODIFY CONSTRAINT costs_channel_fk ENABLE NOVALIDATE;
ALTER TABLE costs
   MODIFY CONSTRAINT costs_promo_fk ENABLE NOVALIDATE;

rem *************************** Creating indexes for SALES table

Prompt ******  Creating indexes for SALES table ....

CREATE BITMAP INDEX sales_prod_bix
   ON sales (prod_id) LOCAL NOLOGGING;

CREATE BITMAP INDEX sales_cust_bix
   ON sales (cust_id) LOCAL NOLOGGING;

CREATE BITMAP INDEX sales_time_bix
   ON sales (time_id) LOCAL NOLOGGING;

CREATE BITMAP INDEX sales_channel_bix
   ON sales (channel_id) LOCAL NOLOGGING;

CREATE BITMAP INDEX sales_promo_bix
   ON sales (promo_id) LOCAL NOLOGGING;

CREATE INDEX sup_text_idx ON supplementary_demographics(comments)
   INDEXTYPE IS ctxsys.context PARAMETERS('nopopulate');

rem *************************** Creating indexes for COSTS table

Prompt ******  Creating indexes for COSTS table ....

CREATE BITMAP INDEX costs_prod_bix
   ON costs (prod_id) LOCAL NOLOGGING;

CREATE BITMAP INDEX costs_time_bix
   ON costs (time_id) LOCAL NOLOGGING;

rem *************************** Creating indexes for PRODUCTS table

Prompt ******  Creating indexes for PRODUCTS table ....

CREATE BITMAP INDEX products_prod_status_bix
   ON products(prod_status) NOLOGGING;

CREATE INDEX products_prod_subcat_ix
   ON products(prod_subcategory) NOLOGGING;

CREATE INDEX products_prod_cat_ix
   ON products(prod_category) NOLOGGING;

CREATE BITMAP INDEX customers_gender_bix
   ON customers(cust_gender) NOLOGGING;

CREATE BITMAP INDEX customers_marital_bix
   ON customers(cust_marital_status) NOLOGGING;

CREATE BITMAP INDEX customers_yob_bix
   ON customers(cust_year_of_birth) NOLOGGING;
   
CREATE BITMAP INDEX FW_PSC_S_MV_SUBCAT_BIX   
   ON fweek_pscat_sales_mv(prod_subcategory);

CREATE BITMAP INDEX FW_PSC_S_MV_CHAN_BIX
   ON fweek_pscat_sales_mv(channel_id);

CREATE BITMAP INDEX FW_PSC_S_MV_PROMO_BIX   
   ON fweek_pscat_sales_mv(promo_id);

CREATE BITMAP INDEX FW_PSC_S_MV_WD_BIX
   ON fweek_pscat_sales_mv(week_ending_day);

rem *************************** Creating dimensions

Prompt ******  Creating dimensions ....

CREATE DIMENSION customers_dim 
   LEVEL customer    IS (customers.cust_id)
   LEVEL city     IS (customers.cust_city_id) 
   LEVEL state     IS (customers.cust_state_province_id) 
   LEVEL country     IS (countries.country_id) 
   LEVEL subregion    IS (countries.country_subregion_id) 
   LEVEL region     IS (countries.country_region_id) 
   LEVEL geog_total   IS (countries.country_total_id) 
   LEVEL cust_total   IS (customers.cust_total_id) 
   HIERARCHY cust_rollup (customer  CHILD OF
                city     CHILD OF 
                state    CHILD OF 
                cust_total)
   HIERARCHY geog_rollup (customer  CHILD OF
                city        CHILD OF 
                state       CHILD OF 
                country     CHILD OF 
                subregion   CHILD OF
                region      CHILD OF
                geog_total
   JOIN KEY (customers.country_id) REFERENCES country)
   ATTRIBUTE customer DETERMINES
   (cust_first_name, cust_last_name, cust_gender,
    cust_marital_status, cust_year_of_birth,
    cust_income_level, cust_credit_limit,
    cust_street_address, cust_postal_code,
    cust_main_phone_number, cust_email)
   ATTRIBUTE city DETERMINES (cust_city) 
   ATTRIBUTE state DETERMINES (cust_state_province) 
   ATTRIBUTE country DETERMINES (countries.country_name,countries.country_iso_code)
   ATTRIBUTE subregion DETERMINES (countries.country_subregion)
   ATTRIBUTE region DETERMINES (countries.country_region) 
   ATTRIBUTE geog_total DETERMINES (countries.country_total) 
   ATTRIBUTE cust_total DETERMINES (customers.cust_total);

CREATE DIMENSION products_dim 
   LEVEL product     IS (products.prod_id)
   LEVEL subcategory   IS (products.prod_subcategory_id) 
   LEVEL category    IS (products.prod_category_id) 
   LEVEL prod_total  IS (products.prod_total_id) 
   HIERARCHY prod_rollup (product  CHILD OF 
                subcategory   CHILD OF 
                category      CHILD OF
                prod_total) 
   ATTRIBUTE product DETERMINES 
         (products.prod_name, products.prod_desc,
          prod_weight_class, prod_unit_of_measure,
          prod_pack_size,prod_status, prod_list_price, prod_min_price)
   ATTRIBUTE subcategory DETERMINES 
         (prod_subcategory, prod_subcategory_desc)
   ATTRIBUTE category DETERMINES 
         (prod_category, prod_category_desc)
   ATTRIBUTE prod_total DETERMINES 
         (prod_total);

CREATE DIMENSION times_dim
   LEVEL day         IS TIMES.TIME_ID
   LEVEL month       IS TIMES.CALENDAR_MONTH_ID
   LEVEL quarter     IS TIMES.CALENDAR_QUARTER_ID
   LEVEL year        IS TIMES.CALENDAR_YEAR_ID
   LEVEL fis_week    IS TIMES.WEEK_ENDING_DAY_ID
   LEVEL fis_month   IS TIMES.FISCAL_MONTH_ID
   LEVEL fis_quarter IS TIMES.FISCAL_QUARTER_ID
   LEVEL fis_year    IS TIMES.FISCAL_YEAR_ID
   HIERARCHY cal_rollup  (day       CHILD OF
                month     CHILD OF
                quarter   CHILD OF
                year)
   HIERARCHY fis_rollup (day CHILD OF
                fis_week     CHILD OF
                fis_month    CHILD OF
                fis_quarter  CHILD OF
                fis_year)
   ATTRIBUTE day DETERMINES 
         (day_number_in_week, day_name, day_number_in_month,
         calendar_week_number)
   ATTRIBUTE month DETERMINES
        (calendar_month_desc,
         calendar_month_number, calendar_month_name,
         days_in_cal_month, end_of_cal_month)
   ATTRIBUTE quarter DETERMINES
         (calendar_quarter_desc,
         calendar_quarter_number,days_in_cal_quarter,
         end_of_cal_quarter)
   ATTRIBUTE year DETERMINES
         (calendar_year,
         days_in_cal_year, end_of_cal_year)
   ATTRIBUTE fis_week DETERMINES
         (week_ending_day,
         fiscal_week_number)
   ATTRIBUTE fis_month DETERMINES
         (fiscal_month_desc, fiscal_month_number, fiscal_month_name,
         days_in_fis_month, end_of_fis_month)
   ATTRIBUTE fis_quarter DETERMINES
         (fiscal_quarter_desc,
         fiscal_quarter_number, days_in_fis_quarter,
         end_of_fis_quarter)
   ATTRIBUTE fis_year DETERMINES
         (fiscal_year,
         days_in_fis_year, end_of_fis_year);

CREATE DIMENSION channels_dim
   LEVEL channel       IS (channels.channel_id) 
   LEVEL channel_class IS (channels.channel_class_id) 
   LEVEL channel_total IS (channels.channel_total_id) 
   HIERARCHY channel_rollup (channel  CHILD OF 
                channel_class  CHILD OF 
                channel_total)
   ATTRIBUTE channel DETERMINES (channel_desc)
   ATTRIBUTE channel_class DETERMINES (channel_class)
   ATTRIBUTE channel_total DETERMINES (channel_total);

CREATE DIMENSION promotions_dim 
   LEVEL promo       IS (promotions.promo_id) 
   LEVEL subcategory   IS (promotions.promo_subcategory_id) 
   LEVEL category       IS (promotions.promo_category_id) 
   LEVEL promo_total   IS (promotions.promo_total_id) 
   HIERARCHY promo_rollup (promo     CHILD OF 
                subcategory   CHILD OF 
                category  CHILD OF
                promo_total) 
   ATTRIBUTE promo DETERMINES 
         (promo_name, promo_cost,
          promo_begin_date, promo_end_date)
   ATTRIBUTE subcategory DETERMINES (promo_subcategory)
   ATTRIBUTE category DETERMINES (promo_category)
   ATTRIBUTE promo_total DETERMINES (promo_total);

rem *************************** Gathering statistics

Prompt ******  Gathering statistics for schema ...

BEGIN
   dbms_stats.gather_schema_stats(
   'SH',
   granularity => 'ALL',
   cascade => TRUE,
   block_sample => TRUE,
   estimate_percent => NULL
);
END;
/
