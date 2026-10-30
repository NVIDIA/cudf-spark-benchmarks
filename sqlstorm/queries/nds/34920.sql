
WITH RECURSIVE SalesRecursion AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit AS net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
        
    UNION ALL
    
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        (sr.net_profit + ws.ws_net_profit) AS net_profit,
        sr.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesRecursion sr ON ws.ws_item_sk = sr.ws_item_sk AND ws.ws_order_number < sr.ws_order_number
    WHERE 
        ws.ws_net_profit > 0
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_profit) AS avg_profit_per_sale,
    MAX(ws.ws_net_profit) AS max_profit_per_sale,
    MIN(ws.ws_net_profit) AS min_profit_per_sale,
    STRING_AGG(DISTINCT r.r_reason_desc, ', ') AS return_reasons
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_returns cr ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
LEFT JOIN 
    reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE 
    ca.ca_state = 'CA'
    AND (c.c_birth_month IS NOT NULL OR c.c_birth_year IS NOT NULL)
    AND (ws.ws_net_profit IS NOT NULL OR ws.ws_net_profit >= 0)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk >= 20200101)
ORDER BY 
    total_profit DESC
LIMIT 10;
