
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesDetails AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        ad.full_address,
        sd.total_sales,
        sd.total_tax,
        sd.order_count
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        AddressDetails ad ON ad.ca_address_sk = cd.c_customer_sk  
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk 
)
SELECT 
    full_name,
    cd_gender,
    full_address,
    total_sales,
    total_tax,
    order_count
FROM 
    CombinedData
WHERE 
    cd_gender = 'F' 
    AND total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 50;
