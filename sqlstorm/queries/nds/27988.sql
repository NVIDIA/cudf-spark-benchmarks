
WITH AddressFormats AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END, 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS FullAddress
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.FullAddress,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressFormats ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS TotalOrders,
        SUM(ws_net_profit) AS TotalProfit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.FullAddress,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ss.TotalOrders,
    ss.TotalProfit
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    (ci.cd_marital_status = 'S' AND ci.cd_purchase_estimate > 1000) 
    OR (ci.cd_gender = 'F' AND ci.cd_education_status LIKE '%Graduate%')
ORDER BY 
    ci.c_last_name, ci.c_first_name;
