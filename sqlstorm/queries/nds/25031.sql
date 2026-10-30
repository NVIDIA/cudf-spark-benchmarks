
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip 
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status, 
        cd_education_status 
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales 
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    a.full_address, 
    d.marital_status, 
    d.cd_gender, 
    d.cd_education_status, 
    COALESCE(s.total_sales, 0) AS total_sales 
FROM 
    customer c 
JOIN 
    AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk 
JOIN 
    DemographicDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk 
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk 
WHERE 
    a.ca_state = 'CA' 
    AND d.cd_gender = 'F' 
    AND d.cd_education_status LIKE '%Bachelor%'
ORDER BY 
    total_sales DESC, 
    c.c_last_name, 
    c.c_first_name
LIMIT 100;
