
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    CASE
        WHEN COUNT(DISTINCT ws.ws_order_number) > 0 THEN 
            ROUND(SUM(ws.ws_net_profit) / COUNT(DISTINCT ws.ws_order_number), 2)
        ELSE 0
    END AS avg_net_profit_per_order
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE
    ca.ca_state IN ('CA', 'NY')
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING
    SUM(ws.ws_net_profit) > 1000
ORDER BY
    total_net_profit DESC;
