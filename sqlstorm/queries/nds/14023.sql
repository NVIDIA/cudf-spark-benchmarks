
SELECT
    c.c_customer_id,
    COUNT(s.ss_ticket_number) AS total_sales,
    SUM(s.ss_ext_sales_price) AS total_sales_amount,
    AVG(s.ss_net_profit) AS average_net_profit
FROM
    customer AS c
JOIN
    store_sales AS s ON c.c_customer_sk = s.ss_customer_sk
WHERE
    s.ss_sold_date_sk BETWEEN 2450000 AND 2450599
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales_amount DESC
LIMIT 100;
