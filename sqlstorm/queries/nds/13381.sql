
SELECT
    SUM(ws_ext_sales_price) AS total_sales,
    d_year AS sales_year,
    d_month_seq AS sales_month
FROM
    web_sales
JOIN
    date_dim ON ws_sold_date_sk = d_date_sk
GROUP BY
    d_year, d_month_seq
ORDER BY
    sales_year, sales_month;
