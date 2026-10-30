
WITH sales_summary AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS sales_count,
        SUM(cs_ext_discount_amt) AS total_discount,
        RANK() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ss.total_sales,
        ss.sales_count,
        ss.total_discount
    FROM 
        sales_summary ss
    JOIN 
        customer_info ci ON ss.cs_bill_customer_sk = ci.c_customer_sk
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.sales_count, 0) AS sales_count,
    COALESCE(tc.total_discount, 0) AS total_discount,
    COALESCE((
        SELECT AVG(total_sales) 
        FROM sales_summary 
        WHERE total_sales > 0
    ), 0) AS avg_sales,
    CASE 
        WHEN tc.total_discount > 100 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_category
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
