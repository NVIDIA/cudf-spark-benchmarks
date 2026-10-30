
SELECT
    c.c_customer_id,
    SUM(cs.cs_sales_price) AS total_sales,
    COUNT(cs.cs_order_number) AS total_orders
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN
    catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
WHERE
    c.c_current_cdemo_sk IS NOT NULL
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales DESC
LIMIT 100;
