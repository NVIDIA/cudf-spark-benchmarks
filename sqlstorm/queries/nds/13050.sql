
SELECT
    c.c_customer_id,
    COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
    SUM(s.ss_net_paid_inc_tax) AS total_revenue,
    AVG(s.ss_net_profit) AS average_profit,
    d.d_year
FROM
    store_sales s
JOIN
    customer c ON s.ss_customer_sk = c.c_customer_sk
JOIN
    date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2020 AND 2023
GROUP BY
    c.c_customer_id, d.d_year
ORDER BY
    total_revenue DESC
LIMIT 100;
