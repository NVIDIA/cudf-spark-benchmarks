
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
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
item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        item i
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
analytics AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        sd.total_quantity_sold,
        sd.total_sales,
        sd.total_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.ca_city ORDER BY sd.total_sales DESC) AS sale_rank
    FROM 
        customer_data cd
    JOIN 
        sales_data sd ON cd.c_customer_sk = sd.ws_item_sk
)
SELECT 
    full_name, 
    ca_city, 
    ca_state, 
    total_quantity_sold, 
    total_sales, 
    total_profit,
    sale_rank 
FROM 
    analytics 
WHERE 
    sale_rank <= 5 
ORDER BY 
    ca_state, 
    total_sales DESC;
