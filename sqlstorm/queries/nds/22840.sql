
WITH customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COUNT(DISTINCT s.s_store_sk) AS store_count,
           COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN store s ON c.c_current_addr_sk = s.s_store_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT c.*, 
           CASE WHEN total_sales > 10000 THEN 'High' ELSE 'Low' END AS value_category
    FROM customer_data c
    WHERE sales_rank <= 10
),
sales_data AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, 
           MAX(ws.ws_net_profit) AS max_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND 
                                      (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT hvc.c_customer_sk, 
       hvc.c_first_name, 
       hvc.c_last_name, 
       hvc.cd_gender, 
       hvc.cd_marital_status, 
       hvc.store_count, 
       hvc.total_sales, 
       hvc.value_category, 
       sd.total_quantity, 
       sd.max_profit
FROM high_value_customers hvc
LEFT JOIN sales_data sd ON hvc.c_customer_sk = sd.ws_sold_date_sk
WHERE (hvc.value_category = 'High' AND sd.total_quantity > 100)
   OR (hvc.value_category = 'Low' AND sd.max_profit IS NULL)
ORDER BY hvc.total_sales DESC, hvc.c_last_name ASC
LIMIT 50;
