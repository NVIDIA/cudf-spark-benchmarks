
SELECT c.c_customer_id, SUM(ss_ext_sales_price) AS total_sales
FROM customer c
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE c.c_birth_year BETWEEN 1970 AND 2000
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY c.c_customer_id
ORDER BY total_sales DESC
LIMIT 100;
