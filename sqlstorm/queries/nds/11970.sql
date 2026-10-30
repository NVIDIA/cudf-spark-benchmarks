
SELECT c.c_customer_id, 
       cd.cd_gender, 
       SUM(ss.ss_net_profit) AS total_net_profit
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY c.c_customer_id, cd.cd_gender
ORDER BY total_net_profit DESC
LIMIT 100;
