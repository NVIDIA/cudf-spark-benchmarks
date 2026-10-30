
SELECT
    UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_customer_name,
    ca.ca_city AS customer_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_quantity_ordered,
    ROUND(AVG(ws.ws_sales_price), 2) AS avg_order_value,
    MAX(CASE WHEN cd.cd_gender = 'F' THEN 'Female' ELSE 'Male' END) AS gender,
    CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
    DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY COUNT(DISTINCT ws.ws_order_number) DESC) AS city_order_rank
FROM
    customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
    ca.ca_state = 'CA' AND
    ws.ws_sold_date_sk > 0
GROUP BY
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, cd.cd_gender, 
    ca.ca_street_number, ca.ca_street_name, ca.ca_street_type
HAVING
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY
    total_quantity_ordered DESC, full_customer_name;
