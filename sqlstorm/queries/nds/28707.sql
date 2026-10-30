
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
shipping_info AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        sm.sm_type,
        sm.sm_carrier,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws.ws_item_sk, ws.ws_ship_mode_sk, sm.sm_type, sm.sm_carrier
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_current_price
    FROM item i
),
combined_info AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        si.sm_type AS shipping_method,
        si.sm_carrier,
        ii.i_product_name,
        ii.i_current_price,
        COUNT(si.total_orders) AS order_count
    FROM customer_info ci
    JOIN shipping_info si ON ci.c_customer_sk = si.ws_item_sk
    JOIN item_info ii ON si.ws_item_sk = ii.i_item_sk
    GROUP BY 
        ci.c_customer_sk, 
        ci.full_name, 
        si.sm_type, 
        si.sm_carrier, 
        ii.i_product_name, 
        ii.i_current_price
)
SELECT 
    full_name,
    shipping_method,
    sm_carrier,
    COUNT(DISTINCT i_product_name) AS unique_products,
    SUM(order_count) AS total_orders,
    ROUND(AVG(i_current_price), 2) AS avg_price
FROM combined_info
GROUP BY full_name, shipping_method, sm_carrier
ORDER BY total_orders DESC, avg_price DESC
LIMIT 10;
