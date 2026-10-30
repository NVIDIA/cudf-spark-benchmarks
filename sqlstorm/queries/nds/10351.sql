
SELECT
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(i.i_current_price) AS average_item_price,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN
    item i ON ss.ss_item_sk = i.i_item_sk
WHERE
    c.c_current_addr_sk IS NOT NULL
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales DESC
LIMIT 100;
