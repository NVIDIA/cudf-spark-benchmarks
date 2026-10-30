
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(ws_net_profit) AS total_net_profit
FROM
    customer_address ca
JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE
    ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
GROUP BY
    ca_state
ORDER BY
    total_net_profit DESC;
