
SELECT
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    a.ca_state,
    d.d_year
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2023
GROUP BY
    c.c_customer_id, a.ca_state, d.d_year
ORDER BY
    total_sales DESC
LIMIT 100;
