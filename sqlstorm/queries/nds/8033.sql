
WITH CustomerPurchases AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, SUM(ws.ws_net_paid) AS total_spent, COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
IncomeBands AS (
    SELECT icd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM household_demographics icd
    JOIN income_band ib ON icd.hd_income_band_sk = ib.ib_income_band_sk
),
CustomerIncome AS (
    SELECT cp.c_customer_sk, cp.total_spent, cp.total_orders, ib.ib_lower_bound, ib.ib_upper_bound
    FROM CustomerPurchases cp
    JOIN customer c ON cp.c_customer_sk = c.c_customer_sk
    LEFT JOIN IncomeBands ib ON ib.hd_income_band_sk = c.c_current_hdemo_sk
)
SELECT ci.c_customer_sk, ci.total_spent, ci.total_orders, ci.ib_lower_bound, ci.ib_upper_bound
FROM CustomerIncome ci
WHERE ci.total_spent > 1000 
ORDER BY ci.total_spent DESC
LIMIT 100;
