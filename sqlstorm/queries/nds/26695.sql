
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ci.FullAddress
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo ci ON c.c_current_addr_sk = ci.ca_address_sk
)
SELECT 
    ci.c_customer_sk,
    CONCAT(ci.c_first_name, ' ', ci.c_last_name) AS FullName,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.FullAddress,
    CASE 
        WHEN LENGTH(ci.c_email_address) > 50 THEN 'Long Email'
        WHEN LENGTH(ci.c_email_address) < 20 THEN 'Short Email'
        ELSE 'Average Email'
    END AS EmailLengthCategory,
    ai.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
    SUM(ws.ws_sales_price) AS TotalSpent
FROM 
    CustomerInfo ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    AddressInfo ai ON ci.FullAddress = ai.FullAddress
GROUP BY 
    ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.c_email_address, 
    ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate, ci.FullAddress, 
    ai.ca_state
ORDER BY 
    TotalSpent DESC;
