WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        CASE
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
    WHERE 
        i.i_category IN ('Electronics', 'Apparel', 'Home & Garden')
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ci.full_name,
        ci.value_category,
        id.i_item_desc,
        id.i_current_price,
        (ws.ws_quantity * ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        ItemDetails id ON ws.ws_item_sk = id.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2457000 AND 2457600  
)
SELECT 
    full_name,
    value_category,
    i_item_desc,
    SUM(total_sales) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS order_count,
    COUNT(ws_item_sk) AS item_count
FROM 
    SalesData
GROUP BY 
    full_name, value_category, i_item_desc
ORDER BY 
    total_sales DESC, order_count DESC
LIMIT 100;