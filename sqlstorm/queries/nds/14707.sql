
SELECT c.c_customer_id, 
       COUNT(ss.ss_ticket_number) AS total_sales, 
       SUM(ss.ss_net_paid_inc_tax) AS total_revenue, 
       MAX(ss.ss_sold_date_sk) AS last_purchase_date
FROM customer c
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE ss.ss_sold_date_sk BETWEEN 20210101 AND 20211231
GROUP BY c.c_customer_id
ORDER BY total_revenue DESC
LIMIT 10;
