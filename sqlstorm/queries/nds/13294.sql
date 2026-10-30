
SELECT
    c.c_customer_id,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss_ticket_number) AS number_of_transactions,
    MAX(ss_sold_date_sk) AS last_purchase_date
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales DESC
LIMIT 10;
