
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        LOWER(i.i_item_desc) AS item_description,
        i.i_current_price
    FROM item i
),
sales_details AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
combined_info AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ii.i_product_name,
        ii.item_description,
        si.total_sold,
        si.total_profit
    FROM customer_info ci
    JOIN sales_details si ON ci.c_customer_sk = si.ws_item_sk
    JOIN item_info ii ON si.ws_item_sk = ii.i_item_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    i_product_name,
    item_description,
    total_sold,
    total_profit,
    CONCAT('Customer: ', full_name, ' | Item: ', i_product_name, ' | Total Sold: ', total_sold) AS summary_info
FROM combined_info
WHERE cd_gender = 'F'
ORDER BY total_profit DESC, total_sold ASC
LIMIT 100;
