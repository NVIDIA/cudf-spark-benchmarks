
SELECT c.c_customer_id, 
       SUM(ss.ss_net_profit) AS total_net_profit, 
       COUNT(ss.ss_ticket_number) AS total_sales, 
       AVG(ss.ss_sales_price) AS average_sales_price 
FROM customer c 
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE c.c_birth_year BETWEEN 1970 AND 1980 
GROUP BY c.c_customer_id 
ORDER BY total_net_profit DESC 
LIMIT 100;
