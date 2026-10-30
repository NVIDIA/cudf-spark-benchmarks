
WITH customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate,
           COALESCE(cd.cd_dep_count, 0) AS dependent_count,
           COALESCE(cd.cd_credit_rating, 'UNKNOWN') AS credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           DENSE_RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
return_data AS (
    SELECT sr.sr_customer_sk,
           SUM(sr.sr_return_amt) AS total_returns,
           COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
final_report AS (
    SELECT ci.c_customer_sk,
           ci.c_first_name,
           ci.c_last_name,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_purchase_estimate,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(rd.total_returns, 0) AS total_returns,
           COALESCE(sd.order_count, 0) AS order_count,
           COALESCE(rd.return_count, 0) AS return_count,
           (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_revenue
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN return_data rd ON ci.c_customer_sk = rd.sr_customer_sk
    WHERE ci.cd_purchase_estimate > 1000 AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
)
SELECT fr.c_customer_sk,
       fr.c_first_name,
       fr.c_last_name,
       fr.total_sales,
       fr.total_returns,
       fr.order_count,
       fr.return_count,
       fr.net_revenue,
       RANK() OVER (ORDER BY fr.net_revenue DESC) AS revenue_rank
FROM final_report fr
WHERE fr.net_revenue IS NOT NULL
ORDER BY fr.net_revenue DESC
LIMIT 10
OFFSET 0;
