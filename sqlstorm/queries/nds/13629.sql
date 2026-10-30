
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(store_sales.ss_sales_price) AS total_sales
FROM
    customer_address
JOIN
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN
    store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
JOIN
    date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
WHERE
    date_dim.d_year = 2023
GROUP BY
    ca_state
ORDER BY
    total_sales DESC
LIMIT 10;
