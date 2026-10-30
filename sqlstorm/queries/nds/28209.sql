
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
        ca_country
    FROM 
        customer_address
),
CustomerFullNames AS (
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
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
AggregateData AS (
    SELECT 
        cfn.full_name,
        ad.full_address,
        ad.city_state_zip,
        ad.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        cfn.cd_gender,
        cfn.cd_marital_status,
        cfn.cd_education_status
    FROM 
        CustomerFullNames cfn
    LEFT JOIN 
        AddressDetails ad ON cfn.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesData sd ON cfn.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    city_state_zip,
    ca_country,
    total_sales,
    order_count,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM 
    AggregateData
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC, full_name;
