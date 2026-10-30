
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ws.ws_sales_price), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
store_sales_data AS (
    SELECT 
        ss.ss_customer_sk,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
),
combined_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.web_order_count,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        COALESCE(ss.store_order_count, 0) AS store_order_count,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales
    FROM 
        customer_sales cs
    LEFT JOIN 
        store_sales_data ss ON cs.c_customer_sk = ss.ss_customer_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS total_sales_rank
    FROM 
        combined_sales c
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name || ' ' || cs.c_last_name AS full_name,
    cs.total_sales,
    cs.total_sales_rank,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year < 1980) AS older_customers_count,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year >= 1980) AS younger_customers_count
FROM 
    sales_summary cs
WHERE 
    cs.total_sales > (SELECT AVG(total_sales) FROM combined_sales)
ORDER BY 
    cs.total_sales_rank;
