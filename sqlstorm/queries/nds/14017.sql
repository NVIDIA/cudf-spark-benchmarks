
SELECT a.ca_city, d.d_year, SUM(ss.ss_sales_price) AS total_sales
FROM customer_address a
JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2023
GROUP BY a.ca_city, d.d_year
ORDER BY total_sales DESC
LIMIT 10;
