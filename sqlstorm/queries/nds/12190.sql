
SELECT
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE
    ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales DESC
LIMIT 10;
