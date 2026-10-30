
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', 
               ca.ca_city, ', ', ca.ca_state) AS full_address,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_location_type
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city LIKE '%New%'
),
DemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    INNER JOIN 
        AddressDetails ad ON ad.ca_address_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    INNER JOIN 
        DemographicDetails dd ON dd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    dd.cd_demo_sk,
    dd.cd_gender,
    dd.cd_marital_status,
    dd.cd_education_status, 
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    DemographicDetails dd
LEFT JOIN 
    SalesData sd ON dd.cd_demo_sk = sd.ws_bill_customer_sk
ORDER BY 
    dd.cd_demo_sk;
