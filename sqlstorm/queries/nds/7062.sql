
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state
    FROM 
        sales_summary ss
    JOIN 
        web_sales w ON ss.ws_item_sk = w.ws_item_sk
    JOIN 
        customer_info ci ON w.ws_ship_customer_sk = ci.c_customer_sk
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.c_first_name,
    ti.c_last_name,
    ti.cd_gender,
    ti.cd_marital_status,
    ti.ca_city,
    ti.ca_state
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    i.i_brand = 'BrandX' 
AND 
    ti.ca_state = 'CA'
ORDER BY 
    ti.total_sales DESC;
