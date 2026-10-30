
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
                   COALESCE(ca.ca_suite_number, ''), ca.ca_city, ca.ca_state, ca.ca_zip, ca.ca_country) AS full_address
    FROM 
        customer_address ca
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ai.full_address,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS order_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F'
    AND si.total_sales > 1000
ORDER BY 
    total_sales DESC;
