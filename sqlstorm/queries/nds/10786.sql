
SELECT
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    d.d_year
FROM
    customer AS c
JOIN
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2021 AND 2023
GROUP BY
    c.c_first_name,
    c.c_last_name,
    d.d_year
ORDER BY
    total_sales DESC
LIMIT 100;
