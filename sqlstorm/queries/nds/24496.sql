
WITH  sales_data AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           SUM(ws_ext_sales_price) AS total_sales_price,
           COUNT(DISTINCT ws_order_number) AS num_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c_customer_sk, 
        c_preferred_cust_flag, 
        cd_marital_status,
        cd_gender,
        cd_purchase_estimate,
        cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY cd_purchase_estimate DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
filtered_sales AS (
    SELECT s.ws_sold_date_sk, s.ws_item_sk, s.total_quantity, s.total_sales_price,
           ci.c_customer_sk, ci.c_preferred_cust_flag, ci.cd_marital_status, ci.cd_gender
    FROM sales_data s
    JOIN customer_info ci ON s.ws_item_sk = ci.c_customer_sk
    WHERE ci.cd_marital_status IN ('M', 'S') 
    AND ci.cd_purchase_estimate IS NOT NULL
    AND (ci.c_preferred_cust_flag = 'Y' OR ci.cd_gender IS NULL)
),
inventory_data AS (
    SELECT inv.inv_item_sk, inv.inv_quantity_on_hand, 
           COALESCE(i.i_current_price, 0) AS current_price
    FROM inventory inv
    LEFT JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand < (SELECT AVG(inv_quantity_on_hand) FROM inventory) 
)
SELECT 
    f.ws_sold_date_sk,
    f.ws_item_sk,
    f.total_quantity,
    f.total_sales_price,
    i.inv_quantity_on_hand,
    i.current_price,
    (f.total_sales_price - (f.total_sales_price * 0.1)) AS adjusted_sales,
    CASE 
        WHEN i.inv_quantity_on_hand IS NULL THEN 'Out of stock'
        ELSE 'In stock'
    END AS stock_status
FROM filtered_sales f
LEFT JOIN inventory_data i ON f.ws_item_sk = i.inv_item_sk
ORDER BY f.total_sales_price DESC, f.ws_sold_date_sk DESC
LIMIT 100
OFFSET 50;

