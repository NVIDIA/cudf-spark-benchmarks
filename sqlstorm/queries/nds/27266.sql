
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ii.i_item_desc,
    ii.i_brand,
    ii.i_category,
    sd.total_quantity,
    sd.total_sales,
    CASE 
        WHEN ci.cd_marital_status = 'M' THEN 'Married'
        WHEN ci.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status,
    CASE 
        WHEN ci.cd_gender = 'M' THEN 'Male'
        WHEN ci.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender
FROM 
    CustomerInfo ci
JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
JOIN 
    ItemInfo ii ON sd.ws_item_sk = ii.i_item_sk
WHERE 
    ci.cd_purchase_estimate > 5000
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
