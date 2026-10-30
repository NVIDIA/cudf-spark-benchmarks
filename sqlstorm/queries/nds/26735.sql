
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_product_name,
        i.i_current_price,
        CAST(LOWER(i.i_item_desc) AS VARCHAR(200)) AS item_description_lower
    FROM item i
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
combined AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ii.i_item_desc,
        ii.i_product_name,
        ss.total_quantity,
        ss.total_sales,
        ss.total_profit,
        ss.total_orders
    FROM customer_info ci
    JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
    JOIN item_info ii ON ss.ws_item_sk = ii.i_item_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    i_product_name,
    total_quantity,
    total_sales,
    total_profit,
    total_orders,
    CASE 
        WHEN total_profit > 1000 THEN 'High Profit'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM combined
WHERE ca_state IN ('CA', 'NY')
ORDER BY total_sales DESC
LIMIT 100;
