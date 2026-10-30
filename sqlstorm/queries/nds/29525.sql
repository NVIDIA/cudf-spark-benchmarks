
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregateData AS (
    SELECT 
        ad.ca_address_sk,
        ad.FullAddress,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.cd_education_status,
        dd.cd_purchase_estimate,
        dd.cd_credit_rating,
        COALESCE(sd.TotalSales, 0) AS TotalSales,
        COALESCE(sd.OrderCount, 0) AS OrderCount
    FROM 
        AddressDetails ad
    LEFT JOIN 
        customer c ON ad.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        DemographicDetails dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
    LEFT JOIN 
        SalesDetails sd ON c.c_customer_sk = sd.customer_sk
)
SELECT 
    FullAddress,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    TotalSales,
    OrderCount
FROM 
    AggregateData
WHERE 
    TotalSales > 1000 
ORDER BY 
    TotalSales DESC;
