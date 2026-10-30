
WITH customer_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_purchase_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
profit_analysis AS (
    SELECT 
        c.c_customer_id,
        cs.total_store_profit,
        cs.total_web_profit,
        cs.store_purchase_count,
        cs.web_purchase_count,
        CASE 
            WHEN cs.total_store_profit > cs.total_web_profit THEN 'Store Preferred'
            WHEN cs.total_web_profit > cs.total_store_profit THEN 'Web Preferred'
            ELSE 'Equal Preference'
        END AS preference
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    preference,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    AVG(total_store_profit) AS avg_store_profit,
    AVG(total_web_profit) AS avg_web_profit,
    SUM(store_purchase_count) AS total_store_purchases,
    SUM(web_purchase_count) AS total_web_purchases
FROM 
    profit_analysis
GROUP BY 
    preference
ORDER BY 
    customer_count DESC;
