
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalData AS (
    SELECT 
        c.full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        s.total_sales,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        CustomerData c
    JOIN 
        AddressData a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(total_sales, 0) AS total_sales,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM 
    FinalData
WHERE 
    total_sales IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 100;
