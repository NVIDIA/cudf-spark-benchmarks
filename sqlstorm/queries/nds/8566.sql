
WITH sales_summary AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_sales_price) AS total_sales,
        AVG(cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        cs_item_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        i.i_category,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.avg_sales_price, 0) AS avg_sales_price,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.cs_item_sk
    WHERE 
        i.i_rec_start_date <= DATE '2002-10-01' 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > DATE '2002-10-01')
), 
customer_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        customer_demographics cd 
    JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    it.i_item_desc,
    it.i_brand,
    it.i_category,
    it.total_quantity,
    it.total_sales,
    it.avg_sales_price,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.order_count
FROM 
    item_details it
JOIN 
    customer_info ci ON it.total_orders > 0
ORDER BY 
    it.total_sales DESC 
LIMIT 100;
