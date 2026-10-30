
WITH AddressDetails AS (
    SELECT 
        CA.ca_address_sk,
        CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type, 
               CASE WHEN CA.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', CA.ca_suite_number) ELSE '' END) AS full_address,
        CA.ca_city,
        CA.ca_state,
        CA.ca_zip,
        CA.ca_country
    FROM 
        customer_address CA
),
CustomerDetails AS (
    SELECT 
        C.c_customer_sk,
        CONCAT(C.c_salutation, ' ', C.c_first_name, ' ', C.c_last_name) AS full_name,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status,
        CD.cd_purchase_estimate
    FROM 
        customer C
    JOIN 
        customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
),
SalesData AS (
    SELECT 
        WS.ws_bill_customer_sk,
        SUM(WS.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT WS.ws_order_number) AS order_count
    FROM 
        web_sales WS
    GROUP BY 
        WS.ws_bill_customer_sk
)
SELECT 
    CONCAT(CD.full_name, ' | ', AD.full_address, ' | ', CD.cd_gender, ' | ', CD.cd_marital_status, 
           ' | ', CD.cd_education_status, ' | ', COALESCE(SD.total_sales, 0), 
           ' | ', COALESCE(SD.order_count, 0)) AS result
FROM 
    CustomerDetails CD
JOIN 
    AddressDetails AD ON CD.c_customer_sk = AD.ca_address_sk
LEFT JOIN 
    SalesData SD ON CD.c_customer_sk = SD.ws_bill_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
