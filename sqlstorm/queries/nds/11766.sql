
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ws_net_profit) AS total_profit
FROM
    customer_address
JOIN
    customer ON ca_address_sk = c_current_addr_sk
JOIN
    web_sales ON c_customer_sk = ws_bill_customer_sk
GROUP BY
    ca_state
ORDER BY
    total_profit DESC
LIMIT 10;
