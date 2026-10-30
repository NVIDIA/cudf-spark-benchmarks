
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        customer_sales
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.sales_rank,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10 Customer'
        WHEN tc.total_sales > (SELECT avg_sales FROM average_sales) THEN 'Above Average Customer'
        ELSE 'Average or Below Customer'
    END AS customer_category,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales Data'
        ELSE CONCAT('Total Sales: $', CAST(ROUND(tc.total_sales, 2) AS STRING))
    END AS sales_summary
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 100
ORDER BY 
    tc.sales_rank;
