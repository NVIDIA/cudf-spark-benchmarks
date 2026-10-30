
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        REPLACE(REPLACE(ca_zip, '-', ''), ' ', '') AS clean_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    ci.full_name,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.clean_zip,
    COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_discount, 0) AS total_discount
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
WHERE 
    ad.ca_state IN ('NY', 'CA')
    AND ci.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
