
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_sales_price) AS total_sales_value
FROM
    customer_address
JOIN
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN
    web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
JOIN
    date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
WHERE
    d_year = 2023
GROUP BY
    ca_state
ORDER BY
    total_sales_value DESC
LIMIT 10;
