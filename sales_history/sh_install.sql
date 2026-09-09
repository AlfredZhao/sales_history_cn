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
rem LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
rem FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
rem DEALINGS IN THE SOFTWARE.
rem
rem NAME
rem   sh_install.sql - Main installation script for SH schema creation
rem
rem DESCRIPTION
rem   SH (Sales History) is a sample schema (add short desc here)
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
rem  This script calls sh_create.sql, sh_populate.sql, sh_code.sql
rem
rem INSTALL INSTRUCTIONS
rem   1. Run as privileged user with rights to create another user
rem      (SYSTEM, ADMIN, etc.)
rem   2. Run this script to create the SH (Sales History) schema
rem   3. You are prompted for
rem      a. password - enter an Oracle Database compliant password
rem      b. tablespace - if you do not enter a tablespace, the default
rem         tablespace is used
rem      c. whether you would like to overwrite the existing schema,
rem         if it is already present in the database
rem
rem UNINSTALL INSTRUCTIONS
rem   If you have installed the SH sample schema, you can remove it by running
rem   the sh_uninstall.sql script
rem
rem NOTES
rem   Run as privileged user with rights to create another user
rem   (SYSTEM, ADMIN, etc.)
rem
rem --------------------------------------------------------------------------

SET ECHO OFF
SET VERIFY OFF
SET HEADING OFF
SET FEEDBACK OFF

-- Exit setup script on any error
WHENEVER SQLERROR EXIT SQL.SQLCODE

rem =======================================================
rem Install descriptions
rem =======================================================

PROMPT
PROMPT Thank you for installing the Oracle Sales History Sample Schema.
PROMPT This installation script will automatically exit your database session
PROMPT at the end of the installation or if any error is encountered.
PROMPT The entire installation will be logged into the 'sh_install.log' log file.
PROMPT

rem =======================================================
rem Log installation process
rem =======================================================

SPOOL sh_install.log

rem =======================================================
rem Accept and verify schema password
rem =======================================================

ACCEPT pass PROMPT 'Enter a password for the user SH: ' HIDE

BEGIN
   IF '&pass' IS NULL THEN
      RAISE_APPLICATION_ERROR(-20999, 'Error: the SH password is mandatory! Please specify a password!');
   END IF;
END;
/

rem =======================================================
rem Accept and verify tablespace name
rem =======================================================

COLUMN property_value NEW_VALUE var_default_tablespace NOPRINT
SELECT property_value FROM database_properties WHERE property_name = 'DEFAULT_PERMANENT_TABLESPACE';

ACCEPT tbs PROMPT 'Enter a tablespace for SH [&var_default_tablespace]: ' DEFAULT '&var_default_tablespace'

DECLARE
   v_tbs_exists   NUMBER := 0;
BEGIN
   SELECT COUNT(1) INTO v_tbs_exists
     FROM DBA_TABLESPACES
       WHERE TABLESPACE_NAME = UPPER('&tbs');
   IF v_tbs_exists = 0 THEN
      RAISE_APPLICATION_ERROR(-20998, 'Error: the tablespace ''' || UPPER('&tbs') || ''' does not exist!');
   END IF;
END;
/

rem =======================================================
rem Data generation options
rem =======================================================

PROMPT
PROMPT 可按“最近 N 个完整自然年加本年截至今天”或指定日期范围生成事实数据。
ACCEPT generation_mode CHAR PROMPT '生成模式 [RECENT|RANGE] [RECENT]: ' DEFAULT 'RECENT'

BEGIN
   IF UPPER(TRIM('&generation_mode')) NOT IN ('RECENT', 'RANGE') THEN
      RAISE_APPLICATION_ERROR(-20993, '生成模式只能是 RECENT 或 RANGE。');
   END IF;
END;
/

COLUMN generation_parameter_script NEW_VALUE generation_parameter_script NOPRINT
SELECT CASE UPPER(TRIM('&generation_mode'))
          WHEN 'RECENT' THEN 'sh_accept_recent.sql'
          ELSE 'sh_accept_range.sql'
       END AS generation_parameter_script
  FROM dual;
@@&generation_parameter_script

rem Validate all generation parameters before an existing SH can be dropped.
DECLARE
   v_mode       VARCHAR2(10) := UPPER(TRIM('&generation_mode'));
   v_start_date DATE;
   v_end_date   DATE;
BEGIN
   IF v_mode = 'RECENT' THEN
      IF TO_NUMBER('&generation_years') < 0 OR TO_NUMBER('&generation_years') > 100 THEN
         RAISE_APPLICATION_ERROR(-20990, '完整自然年数必须在 0 到 100 之间。');
      END IF;
   ELSE
      IF NOT REGEXP_LIKE(TRIM('&generation_start'), '^\d{4}-\d{2}-\d{2}$')
         OR NOT REGEXP_LIKE(TRIM('&generation_end'), '^\d{4}-\d{2}-\d{2}$') THEN
         RAISE_APPLICATION_ERROR(-20991, 'RANGE 模式必须填写 YYYY-MM-DD 格式的起始和结束日期。');
      END IF;
      v_start_date := TO_DATE(TRIM('&generation_start'), 'FXYYYY-MM-DD');
      v_end_date := TO_DATE(TRIM('&generation_end'), 'FXYYYY-MM-DD');
      IF v_start_date > v_end_date THEN
         RAISE_APPLICATION_ERROR(-20992, '起始日期不能晚于结束日期。');
      END IF;
   END IF;
END;
/

rem =======================================================
rem cleanup old SH schema, if found and requested
rem =======================================================

ACCEPT overwrite_schema PROMPT 'SH 已存在时是否覆盖？ [YES|no]: ' DEFAULT 'YES'

SET SERVEROUTPUT ON;
DECLARE
   v_user_exists   all_users.username%TYPE;
BEGIN
   SELECT MAX(username) INTO v_user_exists
      FROM all_users WHERE username = 'SH';
   -- Schema already exists
   IF v_user_exists IS NOT NULL THEN
      -- Overwrite schema if the user chose to do so
      IF UPPER('&overwrite_schema') = 'YES' THEN
         EXECUTE IMMEDIATE 'DROP USER SH CASCADE';
         DBMS_OUTPUT.PUT_LINE('Old SH schema has been dropped.');
      -- or raise error if the user doesn't want to overwrite it
      ELSE
         RAISE_APPLICATION_ERROR(-20997, 'Abort: the schema already exists and the user chose not to overwrite it.');
      END IF;
   END IF;
END;
/
SET SERVEROUTPUT OFF;

rem =======================================================
rem create the SH schema user
rem =======================================================

CREATE USER sh IDENTIFIED BY "&pass"
               DEFAULT TABLESPACE &tbs
               QUOTA UNLIMITED ON &tbs;

GRANT CREATE MATERIALIZED VIEW,
      CREATE DIMENSION,
      CREATE PROCEDURE,
      CREATE SEQUENCE,
      CREATE SESSION,
      CREATE SYNONYM,
      CREATE TABLE,
      CREATE TRIGGER,
      CREATE TYPE,
      CREATE VIEW
  TO sh;

ALTER SESSION SET CURRENT_SCHEMA=SH;
ALTER SESSION SET NLS_LANGUAGE=American;
ALTER SESSION SET NLS_TERRITORY=America;

select 'Start time: ' || systimestamp from dual;

rem =======================================================
rem create SH schema objects
rem =======================================================

@@sh_create.sql

rem =======================================================
rem populate tables with data
rem =======================================================

@@sh_populate.sql

rem =======================================================
rem create Demo views in SH schema
rem =======================================================

@@sh_aireport.sql

rem =======================================================
rem installation validation
rem =======================================================

select 'End time: ' || systimestamp from dual;


SET HEADING ON
rem reactivated by sub-scripts, turn it off again.
SET FEEDBACK OFF

SELECT '安装校验（动态生成表的“预期固定行数”为空）：' AS "安装校验" FROM dual;

SELECT 'channels' AS "Table", 5 AS "provided", count(1) AS "actual" FROM channels
UNION ALL
SELECT 'costs' AS "Table", CAST(NULL AS NUMBER) AS "provided", count(1) AS "actual" FROM costs
UNION ALL
SELECT 'countries' AS "Table", 35 AS "provided", count(1) AS "actual" FROM countries
UNION ALL
SELECT 'customers' AS "Table", 55500 AS "provided", count(1) AS "actual" FROM customers
UNION ALL
SELECT 'products' AS "Table", 72 AS "provided", count(1) AS "actual" FROM products
UNION ALL
SELECT 'promotions' AS "Table", 503 AS "provided", count(1) AS "actual" FROM promotions
UNION ALL
SELECT 'sales' AS "Table", CAST(NULL AS NUMBER) AS "provided", count(1) AS "actual" FROM sales
UNION ALL
SELECT 'times' AS "Table", CAST(NULL AS NUMBER) AS "provided", count(1) AS "actual" FROM times
UNION ALL
SELECT 'supplementary_demographics' AS "Table", 4500 AS "provided", count(1) AS "actual" FROM supplementary_demographics;

rem
rem Installation finish text.
rem
rem the SELECT '' FROM DUAL statements serve to print new lines
rem and make the output more readable.
rem

SELECT '示例模式安装完成。'  AS "安装完成"
   FROM dual
UNION ALL
SELECT '请检查以上安装校验结果。' AS "安装完成"
   FROM dual
UNION ALL
SELECT '' AS "安装完成"
   FROM dual
UNION ALL
SELECT '即将断开数据库连接。' AS "安装完成"
   FROM dual
UNION ALL
SELECT '' AS "安装完成"
   FROM dual
UNION ALL
SELECT '感谢使用 Oracle Database。' AS "安装完成"
   FROM dual
UNION ALL
SELECT '' AS "安装完成"
   FROM dual;

rem stop writing to the log file
spool off

rem
rem Exit from the session.
rem Use 'exit' and not 'disconnect' to keep behavior the same for when errors occur.
rem
exit
