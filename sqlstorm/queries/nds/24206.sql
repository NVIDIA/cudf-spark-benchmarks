
WITH customer_stats AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           COUNT(ss.ss_ticket_number) AS total_store_sales,
           SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(ss.ss_quantity) AS total_quantity_bought,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_profit) DESC) AS rank_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
sales_summary AS (
    SELECT ws.ws_bill_customer_sk,
           COUNT(ws.ws_order_number) AS total_web_sales,
           SUM(ws.ws_net_profit) AS total_web_net_profit,
           AVG(ws.ws_sales_price) AS avg_web_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
combined_sales AS (
    SELECT cs.c_customer_sk,
           COALESCE(cs.total_store_sales, 0) AS store_sales_count,
           COALESCE(cs.total_net_profit, 0) AS store_net_profit,
           COALESCE(ws.total_web_sales, 0) AS web_sales_count,
           COALESCE(ws.total_web_net_profit, 0) AS web_net_profit,
           cs.rank_profit
    FROM customer_stats cs
    FULL OUTER JOIN sales_summary ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT CASE 
           WHEN store_sales_count >= 10 THEN 'Frequent Store Buyer' 
           WHEN store_net_profit = 0 AND web_net_profit = 0 THEN 'Inactive Customer'
           ELSE 'Other'
       END AS customer_category,
       COUNT(*) AS customer_count,
       AVG(store_net_profit) AS avg_store_net_profit,
       SUM(web_net_profit) AS total_web_profit,
       ROUND(AVG(store_sales_count + web_sales_count), 2) AS avg_total_sales,
       SUM(CASE WHEN rank_profit = 1 THEN 1 ELSE 0 END) AS top_profit_customers
FROM combined_sales
GROUP BY customer_category
HAVING SUM(store_sales_count) > 5 OR SUM(web_sales_count) > 5
ORDER BY customer_category DESC;
