
SELECT c_first_name, c_last_name, COUNT(*) AS order_count 
FROM customer 
JOIN store_sales ON c_customer_sk = ss_customer_sk 
GROUP BY c_first_name, c_last_name 
ORDER BY order_count DESC 
LIMIT 10;
