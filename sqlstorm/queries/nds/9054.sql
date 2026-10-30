
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_paid) AS total_spent,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS average_order_value,
    d.d_year,
    SUM(CASE 
        WHEN ws.ws_ship_mode_sk = sm.sm_ship_mode_sk THEN 1 
        ELSE 0 
    END) AS total_standard_shipping,
    COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_dates
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
HAVING 
    SUM(ws.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
