
SELECT
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE
    ss.ss_sold_date_sk BETWEEN (
        SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-01-01'
    ) AND (
        SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-12-31'
    )
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales DESC
LIMIT 100;
