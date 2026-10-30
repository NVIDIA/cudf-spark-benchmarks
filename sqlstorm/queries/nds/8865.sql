
WITH  customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, 
           cd.cd_credit_rating, cd.cd_dep_count, hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
), 
purchase_summary AS (
    SELECT c.c_customer_sk, SUM(ws.ws_net_paid) AS total_spent, COUNT(ws.ws_order_number) AS purchase_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
), 
demographic_distribution AS (
    SELECT cd.cd_gender, cd.cd_marital_status, COUNT(*) AS count, AVG(total_spent) AS avg_spent
    FROM customer_data cd
    JOIN purchase_summary ps ON cd.c_customer_sk = ps.c_customer_sk
    WHERE rank = 1
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT dd.cd_gender, dd.cd_marital_status, dd.count, dd.avg_spent, 
       RANK() OVER (ORDER BY dd.avg_spent DESC) AS spending_rank
FROM demographic_distribution dd
WHERE dd.count > 10
ORDER BY spending_rank;
