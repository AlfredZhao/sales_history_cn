# sales_history_cn
主要修订：针对Oracle提供的sales_history示例数据进行中文化，并将数据更新到2025年6月底

适用场景：仅用于个人测试、PoC场景

作者: Alfred Zhao

日期: 2025-07-15


## 具体说明: 

1.sales和costs这两张事实表，默认到2025年6月底

2.维度表times不适用此脚本，已手工预处理完成，可支持到2025年底

3.其他维度表均已选择性中文化，使其适用于DEMO展示用途

4.支持Oracle Database 23ai EE、SE版，已分别打包如下名称：

	- sh_demo_ee_cn_v202507.zip
	- sh_demo_se_cn_v202507.zip
