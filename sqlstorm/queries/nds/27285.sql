
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk AS demo_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM 
        customer_demographics
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_credit_rating,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM 
    Demographics d
JOIN 
    customer c ON d.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN 
    SalesData sd ON d.cd_demo_sk = sd.demo_sk
WHERE 
    d.cd_gender = 'M'
    AND d.cd_marital_status = 'S'
ORDER BY 
    total_sales DESC
LIMIT 100;
