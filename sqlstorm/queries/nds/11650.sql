SELECT
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_sales
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE
    ca.ca_state = 'CA'
    AND ws.ws_sold_date_sk BETWEEN 2459584 AND 2459649  
GROUP BY
    c.c_first_name,
    c.c_last_name,
    ca.ca_city
ORDER BY
    total_sales DESC
LIMIT 100;