
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
), 
GenderData AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender
), 
SalesData AS (
    SELECT 
        ws_bill_addr_sk AS address_sk,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    gd.cd_gender,
    gd.gender_count,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM 
    AddressData ad
JOIN 
    customer c ON c.c_current_addr_sk = ad.ca_address_sk
JOIN 
    GenderData gd ON c.c_current_cdemo_sk = gd.cd_demo_sk
LEFT JOIN 
    SalesData sd ON ad.ca_address_sk = sd.address_sk
WHERE 
    ad.ca_country = 'USA'
ORDER BY 
    total_sales DESC, ad.ca_city, gd.cd_gender;
