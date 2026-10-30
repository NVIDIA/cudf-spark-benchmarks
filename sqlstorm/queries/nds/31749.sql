WITH  sales_data AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price) AS total_sales, 
           COUNT(ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales
    WHERE ws_ship_date_sk >= 2450000 
    GROUP BY ws_item_sk
),
customer_summary AS (
    SELECT c.c_customer_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_sales_price) AS total_web_sales,
           COUNT(ws.ws_order_number) AS order_count,
           MAX(ws.ws_net_profit) AS max_profit,
           MIN(ws.ws_net_profit) AS min_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
ranked_customers AS (
    SELECT cs.c_customer_sk,
           cs.cd_gender,
           cs.cd_marital_status,
           cs.total_web_sales,
           cs.order_count,
           RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM customer_summary cs
)
SELECT cs.c_customer_sk,
       cs.cd_gender,
       cs.cd_marital_status,
       cs.total_web_sales,
       cs.order_count,
       COALESCE(sd.total_sales, 0) AS web_sales_total,
       CASE 
           WHEN cs.order_count > 50 THEN 'High Volume'
           WHEN cs.order_count BETWEEN 20 AND 50 THEN 'Medium Volume'
           ELSE 'Low Volume'
       END AS sales_category,
       CASE 
           WHEN cs.cd_gender = 'F' THEN 'Female'
           ELSE 'Male'
       END AS gender_label,
       CASE 
           WHEN cs.cd_marital_status IS NULL THEN 'Unknown'
           ELSE cs.cd_marital_status 
       END AS marital_status_label
FROM ranked_customers cs
LEFT JOIN sales_data sd ON cs.c_customer_sk = sd.ws_item_sk
WHERE cs.sales_rank <= 100
ORDER BY cs.total_web_sales DESC;