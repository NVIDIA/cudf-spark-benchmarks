
SELECT SUM(ws_ext_sales_price) AS total_sales
FROM web_sales
JOIN date_dim ON ws_sold_date_sk = d_date_sk
JOIN customer ON ws_bill_customer_sk = c_customer_sk
WHERE d_year = 2023 AND c_birth_country = 'USA';
