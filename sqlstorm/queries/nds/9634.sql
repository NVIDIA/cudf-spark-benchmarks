
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
    d.d_year,
    d.d_month_seq,
    p.p_promo_name
FROM
    customer AS c
JOIN
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN
    promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
WHERE
    d.d_year = 2023
    AND d.d_month_seq BETWEEN 1 AND 12
    AND ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    d.d_year,
    d.d_month_seq,
    p.p_promo_name
HAVING
    SUM(ws.ws_net_profit) > 1000
ORDER BY
    total_net_profit DESC,
    total_orders DESC
LIMIT 100;
