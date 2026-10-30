
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
),
customer_preferences AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
top_items AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_paid
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank <= 10
),
shipping_info AS (
    SELECT 
        sm.sm_ship_mode_sk,
        sm.sm_type,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_sk, sm.sm_type
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_paid,
    si.sm_type,
    si.order_count,
    si.total_revenue
FROM 
    customer_preferences ci
LEFT JOIN 
    top_items ti ON ci.c_customer_sk = ti.ws_item_sk
JOIN 
    shipping_info si ON si.order_count > 100
WHERE 
    (ci.cd_marital_status = 'M' AND ci.cd_gender = 'F') OR ci.cd_marital_status IS NULL
ORDER BY 
    ci.cd_purchase_estimate DESC, ti.total_net_paid DESC
LIMIT 100;
