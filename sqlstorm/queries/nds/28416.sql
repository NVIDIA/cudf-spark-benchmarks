
WITH customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE cd.cd_gender = 'M' AND cd.cd_marital_status = 'M' AND cd.cd_purchase_estimate > 1000
),
store_summary AS (
    SELECT s.s_store_sk, s.s_store_name,
           COUNT(ss.ss_ticket_number) AS total_sales,
           SUM(ss.ss_net_paid) AS total_revenue
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
benchmark_data AS (
    SELECT ci.full_name, ci.email_domain, ss.s_store_name, ss.total_sales, ss.total_revenue
    FROM customer_info ci
    JOIN store_summary ss ON MOD(ci.c_customer_sk, 10) = MOD(ss.s_store_sk, 10)
)
SELECT full_name, email_domain, s_store_name, total_sales, total_revenue,
       CASE 
           WHEN total_revenue > 5000 THEN 'High Value'
           WHEN total_revenue BETWEEN 1000 AND 5000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value
FROM benchmark_data
ORDER BY total_revenue DESC, full_name;
