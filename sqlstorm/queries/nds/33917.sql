
WITH  sales_summary AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_paid) AS total_sales,
           DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY ws_item_sk
), 
customer_data AS (
    SELECT c.c_customer_sk, 
           cd.cd_gender, 
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
), 
datewise_returns AS (
    SELECT d.d_date,
           COALESCE(SUM(sr_return_amt), 0) AS total_return_amount,
           COUNT(sr_ticket_number) AS total_returns
    FROM date_dim d
    LEFT JOIN store_returns sr ON d.d_date_sk = sr.sr_returned_date_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_date
) 
SELECT c.c_customer_sk, 
       c.cd_gender,
       s.total_quantity,
       s.total_sales,
       d.total_return_amount,
       d.total_returns
FROM customer_data c
JOIN sales_summary s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN datewise_returns d ON d.total_returns > 0
WHERE c.total_spent > (
    SELECT AVG(total_spent) 
    FROM customer_data
) 
ORDER BY s.total_sales DESC
LIMIT 10;
