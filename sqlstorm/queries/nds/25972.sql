
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), inventory_data AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
), sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), benchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        inv.total_inventory,
        COALESCE(sd.total_sold, 0) AS total_sold,
        COALESCE(sd.total_profit, 0) AS total_profit,
        CASE 
            WHEN COALESCE(sd.total_sold, 0) = 0 THEN 'No Sales'
            ELSE 'Sold Items'
        END AS sales_status
    FROM customer_info ci
    LEFT JOIN inventory_data inv ON inv.i_item_sk IN (SELECT i.i_item_sk FROM item i)
    LEFT JOIN sales_data sd ON sd.ws_item_sk IN (SELECT i.i_item_sk FROM item i)
    WHERE ci.cd_gender = 'F' AND ci.cd_marital_status = 'M' AND ci.cd_education_status LIKE 'Bachelor%'
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_inventory,
    total_sold,
    total_profit,
    sales_status
FROM benchmark
ORDER BY total_profit DESC;
