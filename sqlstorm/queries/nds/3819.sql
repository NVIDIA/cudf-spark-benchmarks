
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), store_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
), combined_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales
    FROM 
        customer_sales cs
    FULL OUTER JOIN 
        store_sales ss ON cs.c_customer_sk = ss.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    COALESCE(cs.c_first_name, 'Unknown') AS first_name,
    COALESCE(cs.c_last_name, 'Unknown') AS last_name,
    cs.web_sales,
    cs.store_sales,
    (cs.web_sales + cs.store_sales) AS total_sales,
    CASE 
        WHEN (cs.web_sales + cs.store_sales) = 0 THEN NULL
        ELSE ROUND(100.0 * cs.web_sales / NULLIF((cs.web_sales + cs.store_sales), 0), 2)
    END AS web_sales_percentage
FROM 
    combined_sales cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    cs.web_sales > 100 OR cs.store_sales > 100
ORDER BY 
    total_sales DESC
LIMIT 50;
