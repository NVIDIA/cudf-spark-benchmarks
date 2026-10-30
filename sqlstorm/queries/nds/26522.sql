
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
AddressSales AS (
    SELECT 
        ai.full_address,
        ci.full_name,
        si.total_sold,
        si.total_sales
    FROM 
        AddressInfo ai
    JOIN 
        CustomerInfo ci ON ai.ca_address_sk = ci.c_customer_sk
    JOIN 
        SalesInfo si ON ai.ca_address_sk = si.ws_item_sk
)
SELECT 
    full_address,
    full_name,
    COALESCE(total_sold, 0) AS total_sold,
    COALESCE(total_sales, 0.00) AS total_sales,
    CONCAT('Address: ', full_address, ', Customer: ', full_name) AS address_customer_info
FROM 
    AddressSales
ORDER BY 
    total_sales DESC
LIMIT 50;
