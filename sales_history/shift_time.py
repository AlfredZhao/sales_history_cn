#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# --------------------------------------
# 文件名: shift_dates.py
# 描述: 批量平移CSV文件中的日期字段
# 作者: Alfred Zhao
# 日期: 2025-07-02
# 说明: 目前保留是每次平移6个月（可调整）
# 只针对sales和costs这两张事实表，目前默认到2025年6月底
# 维度表times不适用此脚本，已手工预处理完成，可支持到2025年底
# 其他维度表均已选择性中文化，使其适用于DEMO展示用途
# --------------------------------------

import csv
from datetime import datetime
from dateutil.relativedelta import relativedelta

def shift_time_id(input_file, output_file, time_column='TIME_ID', date_format='%Y-%m-%d'):
    with open(input_file, newline='', encoding='utf-8') as infile, \
         open(output_file, 'w', newline='', encoding='utf-8') as outfile:

        reader = csv.DictReader(infile)
        fieldnames = reader.fieldnames
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()

        for row in reader:
            try:
                original_date = datetime.strptime(row[time_column], date_format)
                new_date = original_date + relativedelta(months=6)
                row[time_column] = new_date.strftime(date_format)
            except Exception as e:
                print(f"Error parsing date '{row[time_column]}': {e}")
            writer.writerow(row)

# 批量处理两个文件
shift_time_id('sales.csv', 'sales_shifted.csv')
shift_time_id('costs.csv', 'costs_shifted.csv')
