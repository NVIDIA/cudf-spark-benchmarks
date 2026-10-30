
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        TRIM(LEADING '0' FROM ca_zip) AS formatted_zip,
        ca_address_sk
    FROM 
        customer_address
),
GenderCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        cd_demo_sk
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender,
        cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.formatted_zip,
    gc.gender_count,
    ss.total_sales,
    ss.transaction_count
FROM 
    AddressDetails ad
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN 
    GenderCounts gc ON c.c_current_cdemo_sk = gc.cd_demo_sk
LEFT JOIN 
    SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ad.ca_state IN ('CA', 'NY')
ORDER BY 
    ss.total_sales DESC, 
    ad.ca_city ASC, 
    ad.formatted_zip;
