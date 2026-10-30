
WITH CustomerFullName AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
CombinedData AS (
    SELECT 
        cfn.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        sd.total_sales
    FROM 
        CustomerFullName cfn
    JOIN 
        AddressDetails ad ON cfn.c_customer_sk = ad.ca_address_sk
    JOIN 
        SalesDetails sd ON cfn.c_customer_sk = sd.ws_order_number
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    LENGTH(full_name) AS name_length,
    LENGTH(full_address) AS address_length,
    UPPER(ca_state) AS state_upper,
    LOWER(ca_city) AS city_lower
FROM 
    CombinedData
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
