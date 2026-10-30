
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), CombinedData AS (
    SELECT 
        cust.c_customer_sk,
        cust.full_name,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip,
        addr.ca_country,
        cust.cd_gender,
        cust.cd_marital_status,
        cust.cd_education_status,
        cust.cd_purchase_estimate
    FROM 
        CustomerData cust
    JOIN 
        AddressData addr ON cust.c_customer_sk = addr.ca_address_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    COUNT(*) AS purchase_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    CombinedData
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = CombinedData.c_customer_sk
GROUP BY 
    full_name, full_address, ca_city, ca_state, ca_zip
ORDER BY 
    purchase_count DESC, avg_purchase_estimate DESC
LIMIT 100;
