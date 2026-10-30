
SELECT
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE
    c.c_birth_year BETWEEN 1970 AND 1990
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600
GROUP BY
    c.c_first_name, c.c_last_name
ORDER BY
    total_sales DESC
LIMIT 100;
