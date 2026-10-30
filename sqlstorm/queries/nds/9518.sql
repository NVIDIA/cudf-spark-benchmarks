
WITH customer_data AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           cd.cd_dep_count,
           cd.cd_dep_employed_count,
           cd.cd_dep_college_count,
           ca.ca_city,
           ca.ca_state,
           ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT ws.ws_ship_customer_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(ws.ws_order_number) AS total_orders,
           COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM web_sales ws
    GROUP BY ws.ws_ship_customer_sk
),
summary_data AS (
    SELECT cd.c_customer_sk,
           cd.c_first_name,
           cd.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           sd.total_net_profit,
           sd.total_orders,
           sd.unique_items_sold
    FROM customer_data cd
    LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
)
SELECT *,
       CASE 
           WHEN total_net_profit IS NULL THEN 'No Sales'
           WHEN total_net_profit < 0 THEN 'Loss'
           ELSE 'Profit'
       END AS sales_status
FROM summary_data
ORDER BY total_net_profit DESC, total_orders DESC
LIMIT 100;
