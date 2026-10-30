
WITH  address_summary AS (
    SELECT ca_address_id, 
           ca_city, 
           ca_state,
           COUNT(*) AS total_addresses
    FROM customer_address
    GROUP BY ca_address_id, ca_city, ca_state
),
customer_info AS (
    SELECT c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
date_sales AS (
    SELECT d.d_date_id, 
           SUM(ws.ws_net_profit) AS total_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_id
),
item_average_price AS (
    SELECT i.i_item_id, 
           AVG(ws.ws_sales_price) AS avg_price
    FROM item i
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY i.i_item_id
)
SELECT ci.c_customer_id, 
       ci.c_first_name, 
       ci.c_last_name, 
       ci.cd_gender,
       ci.rank_by_gender,
       asum.total_addresses,
       ds.total_sales,
       iap.avg_price
FROM customer_info ci
FULL OUTER JOIN address_summary asum ON ci.c_customer_id = asum.ca_address_id
LEFT JOIN date_sales ds ON ds.d_date_id = (
    SELECT d.d_date_id
    FROM date_dim d
    WHERE d.d_year = 2023
    ORDER BY d.d_date DESC
    LIMIT 1
)
JOIN item_average_price iap ON ci.c_customer_id = (
    SELECT MIN(c.c_customer_id)
    FROM customer c
    WHERE c.c_customer_sk IN (1, 2, 3)
)
WHERE (ci.cd_marital_status = 'S' OR ci.cd_marital_status IS NULL)
  AND (asum.ca_city IN ('San Francisco', 'New York') OR asum.ca_state IS NULL)
ORDER BY ci.c_last_name, ci.c_first_name
LIMIT 100;
