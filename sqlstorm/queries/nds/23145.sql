
WITH customer_orders AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
income_distribution AS (
    SELECT cd.cd_demo_sk, 
           CASE 
               WHEN ib.ib_income_band_sk IS NOT NULL THEN ib.ib_income_band_sk 
               ELSE 0 
           END AS income_band,
           COUNT(*) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY cd.cd_demo_sk, ib.ib_income_band_sk
),
aggregated_data AS (
    SELECT co.c_customer_id, 
           co.total_quantity, 
           co.total_profit,
           id.income_band,
           id.customer_count,
           RANK() OVER (PARTITION BY id.income_band ORDER BY co.total_profit DESC) AS profit_rank
    FROM customer_orders co
    JOIN income_distribution id ON co.c_customer_sk = id.cd_demo_sk
)
SELECT a.c_customer_id,
       a.total_quantity,
       a.total_profit,
       a.income_band,
       a.customer_count,
       CASE 
           WHEN a.profit_rank <= 10 THEN 'Top Performer' 
           ELSE 'Regular' 
       END AS performance_category
FROM aggregated_data a
WHERE a.total_profit IS NOT NULL
  AND a.total_quantity > 0
ORDER BY a.income_band, a.total_profit DESC;
