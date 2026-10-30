
WITH  sales_ranking AS (
    SELECT 
        ws_order_number,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_order_number,
        ws_ship_mode_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        MAX(ws.ws_net_profit) AS max_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.avg_net_paid,
        cs.max_net_profit
    FROM 
        customer_stats cs
    WHERE 
        cs.avg_net_paid > (
            SELECT AVG(avg_net_paid) FROM customer_stats
        )
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_web_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(CASE WHEN ws.ws_ship_mode_sk IS NOT NULL THEN 1 ELSE 0 END) AS direct_ship_orders,
    RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
FROM 
    high_value_customers hvc
JOIN 
    customer c ON hvc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND (ws.ws_sales_price IS NOT NULL OR ws.ws_sales_price > 100)
GROUP BY 
    c.c_customer_id, 
    ca.ca_city
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_web_sales DESC
LIMIT 10;
