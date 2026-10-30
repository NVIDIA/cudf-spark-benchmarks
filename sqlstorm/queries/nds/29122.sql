
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name)) AS address_length
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk, 
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
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Combined AS (
    SELECT 
        c.c_customer_sk,
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        s.total_sales,
        s.order_count,
        a.address_length
    FROM 
        CustomerData c
    LEFT JOIN 
        AddressData a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    order_count,
    address_length
FROM 
    Combined
WHERE 
    ca_state = 'CA' 
ORDER BY 
    total_sales DESC, 
    order_count DESC;
