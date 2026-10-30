
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    a.ca_city,
    a.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(ss.ss_net_profit) AS total_store_net_profit
FROM
    customer c
JOIN
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE
    a.ca_state IN ('NY', 'CA')
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state
HAVING
    COUNT(DISTINCT ws.ws_order_number) > 5 OR COUNT(DISTINCT ss.ss_ticket_number) > 10
ORDER BY
    total_web_net_profit DESC, total_store_net_profit DESC
LIMIT 100;
