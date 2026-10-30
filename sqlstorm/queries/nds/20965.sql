
WITH RecursiveTimeFrame AS (
    SELECT d_year, d_month_seq, d_week_seq, d_dow, d_moy 
    FROM date_dim 
    WHERE d_date >= '2022-01-01' AND d_date <= '2022-12-31'
),
FilteredCustomers AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating 
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE cd.cd_marital_status IN ('M', 'S') 
      AND cd.cd_credit_rating IS NOT NULL
),
SalesInfo AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_net_profit) AS total_profit, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank 
    FROM web_sales ws 
    JOIN FilteredCustomers fc ON ws.ws_bill_customer_sk = fc.c_customer_sk 
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY ws.ws_bill_customer_sk
),
TopProfitableCustomers AS (
    SELECT fc.c_customer_id, fc.c_first_name, fc.c_last_name, si.total_profit 
    FROM FilteredCustomers fc 
    JOIN SalesInfo si ON fc.c_customer_sk = si.ws_bill_customer_sk 
    WHERE si.profit_rank <= 5
)
SELECT t.d_year, t.d_month_seq, COUNT(DISTINCT tc.c_customer_id) AS unique_customers, 
       SUM(COALESCE(tc.total_profit, 0)) AS aggregated_profit,
       CASE 
           WHEN SUM(tc.total_profit) > 10000 THEN 'High Value'
           WHEN SUM(tc.total_profit) BETWEEN 5000 AND 10000 THEN 'Medium Value'
           ELSE 'Low Value' 
       END AS customer_value_segment
FROM RecursiveTimeFrame t 
LEFT JOIN TopProfitableCustomers tc ON t.d_year = 2022 
GROUP BY t.d_year, t.d_month_seq 
ORDER BY t.d_year, t.d_month_seq;
