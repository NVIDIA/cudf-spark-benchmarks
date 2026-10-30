
WITH  customer_loyalty AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_marital_status, cd.cd_gender, 
           COUNT(ss.ss_ticket_number) AS total_purchases,
           SUM(ss.ss_net_profit) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, 
             cd.cd_marital_status, cd.cd_gender
),
customer_in_top_income AS (
    SELECT h.hd_demo_sk, h.hd_income_band_sk, 
           ib.ib_lower_bound, ib.ib_upper_bound
    FROM household_demographics h
    JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    WHERE (ib.ib_upper_bound - ib.ib_lower_bound) > 10000
)
SELECT cl.c_customer_sk, cl.c_first_name, cl.c_last_name,
       cl.total_purchases, cl.total_spent, 
       CASE 
           WHEN cl.total_purchases IS NULL THEN 'No Purchases'
           WHEN cl.total_purchases > 5 THEN 'Regular Customer'
           ELSE 'New Customer' 
       END AS customer_status,
       CASE 
           WHEN cl.total_spent > (SELECT AVG(total_spent) FROM customer_loyalty)
           THEN 'Above Average Spender' 
           ELSE 'Below Average Spender' 
       END AS spending_level,
       EXISTS (SELECT 1 
               FROM customer_in_top_income ci 
               WHERE ci.hd_demo_sk = cl.c_customer_sk) AS in_top_income_band,
       COALESCE(sm.sm_type, 'Standard') AS ship_mode_type
FROM customer_loyalty cl
LEFT JOIN web_sales ws ON cl.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY cl.c_customer_sk, cl.c_first_name, cl.c_last_name, 
         cl.total_purchases, cl.total_spent, 
         sm.sm_type
ORDER BY total_spent DESC
LIMIT 100 OFFSET 10;
