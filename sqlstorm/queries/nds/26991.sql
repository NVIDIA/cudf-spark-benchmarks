
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
final_benchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ii.i_item_desc,
        ii.i_brand,
        ss.total_quantity_sold,
        ss.avg_sales_price,
        ss.total_net_profit
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
    JOIN 
        item_info ii ON ss.ws_item_sk = ii.i_item_sk
    WHERE 
        ci.cd_gender = 'F' AND
        ci.cd_marital_status = 'M' AND
        ii.i_current_price > 20.00
)
SELECT 
    *,
    LENGTH(full_name) AS name_length,
    POSITION(' ' IN full_name) AS space_position,
    REPLACE(i_item_desc, ' ', '-') AS item_description_dashed
FROM 
    final_benchmark
ORDER BY 
    total_net_profit DESC, 
    total_quantity_sold DESC;
