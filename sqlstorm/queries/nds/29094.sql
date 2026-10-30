
WITH AddressDetails AS (
    SELECT 
        CA.ca_address_sk,
        CA.ca_city,
        CA.ca_state,
        CA.ca_zip,
        CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type) AS full_address
    FROM 
        customer_address CA
),
CustomerInfo AS (
    SELECT 
        C.c_customer_sk,
        C.c_first_name,
        C.c_last_name,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status,
        AD.full_address,
        AD.ca_city,
        AD.ca_state
    FROM 
        customer C
    JOIN customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN AddressDetails AD ON C.c_current_addr_sk = AD.ca_address_sk
),
SalesSummary AS (
    SELECT 
        CC.cc_call_center_sk,
        SUM(CASE WHEN WS.ws_sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS web_sales_count,
        SUM(CASE WHEN CS.cs_sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS catalog_sales_count,
        SUM(CASE WHEN SS.ss_sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS store_sales_count
    FROM 
        call_center CC
    LEFT JOIN web_sales WS ON CC.cc_call_center_sk = WS.ws_ship_cdemo_sk
    LEFT JOIN catalog_sales CS ON CC.cc_call_center_sk = CS.cs_call_center_sk
    LEFT JOIN store_sales SS ON CC.cc_call_center_sk = SS.ss_cdemo_sk
    GROUP BY 
        CC.cc_call_center_sk
)
SELECT 
    CI.c_first_name,
    CI.c_last_name,
    CI.ca_city,
    CI.ca_state,
    SS.web_sales_count,
    SS.catalog_sales_count,
    SS.store_sales_count
FROM 
    CustomerInfo CI
JOIN 
    SalesSummary SS ON CI.c_customer_sk = SS.cc_call_center_sk
WHERE 
    CI.ca_state = 'CA'
ORDER BY 
    CI.c_last_name, CI.c_first_name;
