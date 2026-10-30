
WITH  sales_hierarchy AS (
    SELECT ss_store_sk, 
           SUM(ss_net_paid) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (
        SELECT MIN(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ss_store_sk
),
customer_summary AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           SUM(ws.ws_net_paid) AS total_web_sales,
           SUM(ss.ss_net_paid) AS total_store_sales,
           COALESCE(SUM(ws.ws_net_paid), 0) + COALESCE(SUM(ss.ss_net_paid), 0) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT c.*, 
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_summary c
    WHERE c.total_sales > (
        SELECT AVG(total_sales) 
        FROM customer_summary
    )
)
SELECT t.c_first_name, 
       t.c_last_name, 
       t.cd_gender,
       s.total_sales AS store_sales,
       w.total_web_sales AS web_sales,
       t.sales_rank,
       CASE 
           WHEN t.sales_rank <= 10 THEN 'Top Customer'
           WHEN t.sales_rank <= 50 THEN 'Average Customer'
           ELSE 'Low spender'
       END AS customer_category,
       COALESCE(sm.sm_type, 'N/A') AS preferred_ship_mode
FROM top_customers t
LEFT JOIN sales_hierarchy s ON t.c_customer_sk = s.ss_store_sk
LEFT JOIN (
    SELECT ws_ship_mode_sk, 
           SUM(ws_net_paid) AS total_web_sales
    FROM web_sales
    GROUP BY ws_ship_mode_sk
) w ON t.c_customer_sk = w.ws_ship_mode_sk
LEFT JOIN ship_mode sm ON w.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE t.sales_rank <= 100;

