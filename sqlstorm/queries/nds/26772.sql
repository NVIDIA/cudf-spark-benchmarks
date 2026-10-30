
SELECT
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
    COALESCE(ROUND(AVG(ws.ws_sales_price), 2), 0) AS avg_sales_price,
    SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_username,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_quantity) DESC) AS city_rank
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN
    web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
LEFT JOIN
    store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
GROUP BY
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, c.c_email_address
HAVING
    SUM(ws.ws_quantity) > 100
ORDER BY
    city_rank, total_quantity_sold DESC;
