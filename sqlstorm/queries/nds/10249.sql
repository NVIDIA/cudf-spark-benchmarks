
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM
    customer AS c
JOIN
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN
    web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE
    ws.ws_sold_date_sk BETWEEN 1 AND 365
GROUP BY
    c.c_customer_sk, c.c_first_name, c.c_last_name
ORDER BY
    total_net_profit DESC
LIMIT 100;
