
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    SUM(ws_ext_sales_price) AS total_sales
FROM
    customer_address
JOIN
    customer ON customer_address.ca_address_sk = customer.c_current_addr_sk
JOIN
    web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
JOIN
    date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
GROUP BY
    ca_state
HAVING
    SUM(ws_ext_sales_price) > 10000
ORDER BY
    total_sales DESC;
