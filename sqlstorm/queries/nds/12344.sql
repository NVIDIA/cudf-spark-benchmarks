
SELECT c_first_name, c_last_name, SUM(ss_ext_sales_price) AS total_sales
FROM customer
JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
WHERE d_year = 2023
GROUP BY c_first_name, c_last_name
ORDER BY total_sales DESC
LIMIT 10;
