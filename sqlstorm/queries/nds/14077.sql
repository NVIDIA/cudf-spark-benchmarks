
SELECT
    c.c_customer_id,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS total_orders
FROM
    customer AS c
JOIN
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2023
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales DESC
LIMIT 10;
