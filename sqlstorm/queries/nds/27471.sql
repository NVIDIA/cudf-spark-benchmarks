
SELECT
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS avg_order_value,
    SUM(ws.ws_net_profit) AS total_profit
FROM
    customer_address ca
JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE
    dd.d_year = 2023
    AND (LOWER(ca.ca_city) LIKE '%city%' OR LOWER(ca.ca_city) LIKE '%town%')
    AND ws.ws_net_profit > 0
GROUP BY
    ca.ca_city
ORDER BY
    total_profit DESC
LIMIT 10;
