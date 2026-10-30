
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ss.ss_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        CASE 
            WHEN SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ss.ss_sales_price, 0)) > 1000 THEN 'High Value'
            WHEN SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ss.ss_sales_price, 0)) > 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.web_order_count,
        cs.catalog_order_count,
        cs.store_order_count,
        cs.customer_value,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    t.c_customer_id,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.web_order_count,
    t.catalog_order_count,
    t.store_order_count,
    t.customer_value
FROM 
    top_customers t
WHERE 
    t.sales_rank <= 10;
