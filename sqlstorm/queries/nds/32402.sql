
WITH  sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.total_orders,
        RANK() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS total_sales_rank
    FROM 
        customer c
    LEFT JOIN 
        sales_summary ss ON c.c_customer_sk = ss.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
), 
sales_analysis AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.total_orders,
        CASE 
            WHEN tc.total_sales > 10000 THEN 'High Value'
            WHEN tc.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment,
        DENSE_RANK() OVER (ORDER BY tc.total_sales DESC) AS value_segment_rank
    FROM 
        top_customers tc
    WHERE 
        tc.total_sales > 0
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.total_sales,
    sa.total_orders,
    sa.customer_value_segment,
    sa.value_segment_rank,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = sa.c_customer_sk) AS store_sales_count,
    (SELECT COUNT(*)
     FROM catalog_sales cs 
     WHERE cs.cs_bill_customer_sk = sa.c_customer_sk) AS catalog_sales_count,
    COALESCE((SELECT SUM(sr_return_quantity)
              FROM store_returns sr 
              WHERE sr.sr_customer_sk = sa.c_customer_sk), 0) AS total_store_returns,
    COALESCE((SELECT SUM(cr_return_quantity)
              FROM catalog_returns cr 
              WHERE cr.cr_returning_customer_sk = sa.c_customer_sk), 0) AS total_catalog_returns
FROM 
    sales_analysis sa
WHERE 
    sa.value_segment_rank <= 10;
