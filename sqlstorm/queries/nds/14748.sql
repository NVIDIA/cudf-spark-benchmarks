
SELECT
    c.c_customer_id,
    sum(ss.ss_sales_price) AS total_sales,
    count(ss.ss_ticket_number) AS number_of_transactions
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales DESC
LIMIT 10;
