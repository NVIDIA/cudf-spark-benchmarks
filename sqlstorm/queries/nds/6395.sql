
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk
),
Store_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk
),
Combined_Sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_profit,
        cs.web_order_count,
        ss.total_store_profit,
        ss.store_order_count
    FROM 
        Customer_Sales cs
    JOIN 
        Store_Sales ss ON cs.c_customer_sk = ss.c_customer_sk
),
Final_Report AS (
    SELECT 
        c.c_customer_id,
        cs.total_web_profit,
        cs.web_order_count,
        COALESCE(ss.total_store_profit, 0) AS total_store_profit,
        COALESCE(ss.store_order_count, 0) AS store_order_count,
        (cs.total_web_profit + COALESCE(ss.total_store_profit, 0)) AS total_profit,
        (cs.web_order_count + COALESCE(ss.store_order_count, 0)) AS total_order_count
    FROM 
        customer c
    LEFT JOIN 
        Combined_Sales cs ON c.c_customer_sk = cs.c_customer_sk
    LEFT JOIN 
        Store_Sales ss ON c.c_customer_sk = ss.c_customer_sk
)
SELECT 
    *,
    (CASE 
        WHEN total_order_count = 0 THEN 0 
        ELSE total_profit / total_order_count 
     END) AS average_profit_per_order
FROM 
    Final_Report
ORDER BY 
    total_profit DESC
LIMIT 100;
