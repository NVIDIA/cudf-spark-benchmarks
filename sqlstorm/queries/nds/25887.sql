
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
            CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                 THEN CONCAT(' Suite ', ca_suite_number) 
                 ELSE '' END)) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS FullName,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ad.FullAddress,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails AS ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS TotalOrders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.FullName,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ci.FullAddress,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.ca_country,
    COALESCE(sd.TotalSales, 0) AS TotalSales,
    COALESCE(sd.TotalOrders, 0) AS TotalOrders
FROM CustomerInfo AS ci
LEFT JOIN SalesData AS sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY ci.FullName;
