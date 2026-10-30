SELECT c.c_customer_id, 
       sum(ss.ss_net_paid) AS total_sales, 
       cd.cd_gender, 
       cd.cd_marital_status, 
       count(ss.ss_ticket_number) AS transaction_count
FROM customer c
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_sold_date_sk BETWEEN 1 AND 100  
GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
ORDER BY total_sales DESC
LIMIT 100;