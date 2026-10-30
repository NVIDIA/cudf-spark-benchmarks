
SELECT
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss_customer_sk) AS total_customers,
    AVG(ss_quantity) AS average_quantity_sold
FROM
    store_sales
JOIN
    date_dim ON ss_sold_date_sk = d_date_sk
JOIN
    customer ON ss_customer_sk = c_customer_sk
WHERE
    d_year = 2023
GROUP BY
    d_month_seq
ORDER BY
    d_month_seq;
