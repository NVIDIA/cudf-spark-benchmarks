
WITH ProcessedCustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        TRIM(UPPER(COALESCE(c.c_email_address, ''))) AS normalized_email,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender_description,
        COALESCE(cd.cd_education_status, 'Not Specified') AS education_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressSummary AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS complete_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    p.full_name,
    p.normalized_email,
    p.gender_description,
    p.education_status,
    a.complete_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_orders, 0) AS total_orders
FROM 
    ProcessedCustomerData p
LEFT JOIN 
    AddressSummary a ON p.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    SalesSummary s ON p.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    LENGTH(p.normalized_email) > 0
ORDER BY 
    p.full_name;
