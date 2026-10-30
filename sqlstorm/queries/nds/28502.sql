
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    d.d_date AS return_date, 
    SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_quantity ELSE 0 END) AS total_returns,
    COUNT(DISTINCT sr_ticket_number) AS return_count,
    SUM(sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ws_order_number) AS web_order_count,
    SUM(ws_net_profit) AS total_web_profit
FROM 
    customer c
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
    AND (c.c_birth_country = 'USA' OR c.c_birth_country IS NULL)
GROUP BY 
    c.c_customer_id, full_name, d.d_date
ORDER BY 
    total_returns DESC, total_return_amount DESC
LIMIT 100;
