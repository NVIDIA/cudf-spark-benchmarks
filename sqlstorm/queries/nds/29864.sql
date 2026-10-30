
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
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
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
category_sales AS (
    SELECT 
        ii.i_category,
        SUM(si.total_sold) AS category_sold,
        SUM(si.total_sales) AS category_sales
    FROM 
        sales_info si
    JOIN 
        item_info ii ON si.ws_item_sk = ii.i_item_sk
    GROUP BY 
        ii.i_category
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    cs.category_sold,
    cs.category_sales,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country
FROM 
    customer_info ci
JOIN 
    category_sales cs ON cs.category_sales > 1000
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    cs.category_sales DESC
LIMIT 50;
