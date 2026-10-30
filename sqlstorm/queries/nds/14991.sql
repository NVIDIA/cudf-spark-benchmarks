
SELECT
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss_customer_sk) AS unique_customers,
    AVG(ss_net_profit) AS average_profit
FROM
    store_sales
WHERE
    ss_sold_date_sk BETWEEN 1 AND 1000
GROUP BY
    ss_store_sk
ORDER BY
    total_sales DESC
LIMIT 10;
