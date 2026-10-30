
WITH customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, 
           d.d_year, d.d_month_seq, d.d_week_seq
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 5000
), sales_data AS (
    SELECT ss.ss_customer_sk, SUM(ss.ss_net_paid) AS total_spent, COUNT(ss.ss_ticket_number) AS total_purchases
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss.ss_customer_sk
), return_data AS (
    SELECT sr.sr_customer_sk, SUM(sr.sr_return_amt) AS total_returns
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY sr.sr_customer_sk
)
SELECT cd.c_first_name, cd.c_last_name, cd.cd_gender, 
       COALESCE(sd.total_spent, 0) AS total_spent, 
       COALESCE(sd.total_purchases, 0) AS total_purchases, 
       COALESCE(rd.total_returns, 0) AS total_returns
FROM customer_data cd
LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ss_customer_sk
LEFT JOIN return_data rd ON cd.c_customer_sk = rd.sr_customer_sk
ORDER BY cd.c_last_name, cd.c_first_name;
