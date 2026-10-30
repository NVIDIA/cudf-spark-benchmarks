
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CHR(10) AS line_break,
        c_email_address,
        REPLACE(LOWER(c_email_address), ' ', '') AS sanitized_email
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.full_address,
    sd.total_sales,
    sd.total_orders,
    LOWER(ci.sanitized_email) AS email_reduction
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ai.ca_city IS NOT NULL AND
    (ci.cd_gender = 'M' OR ci.cd_marital_status = 'M')
ORDER BY 
    total_sales DESC
LIMIT 100;
