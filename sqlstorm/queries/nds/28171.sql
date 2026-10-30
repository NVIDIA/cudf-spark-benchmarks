
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        SUBSTRING(ca_city, 1, 3) AS city_prefix,
        ca_state,
        REPLACE(ca_zip, '-', '') AS zip_code
    FROM 
        customer_address
), DemographicData AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS demographic_info,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
), AddressCounts AS (
    SELECT 
        a.ca_address_sk,
        COUNT(*) AS address_count
    FROM 
        AddressParts a
    JOIN 
        customer c ON c.c_current_addr_sk = a.ca_address_sk
    GROUP BY 
        a.ca_address_sk
), ExtendedInfo AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        d.demographic_info,
        d.cd_purchase_estimate,
        ad.address_count
    FROM 
        AddressParts a
    JOIN 
        customer c ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicData d ON d.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        AddressCounts ad ON ad.ca_address_sk = a.ca_address_sk
)
SELECT 
    e.full_address,
    e.demographic_info,
    e.cd_purchase_estimate,
    e.address_count,
    CASE 
        WHEN e.cd_purchase_estimate >= 1000 THEN 'High Value Customer'
        WHEN e.cd_purchase_estimate BETWEEN 500 AND 999 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    ExtendedInfo e
WHERE 
    e.address_count > 1
ORDER BY 
    e.full_address, e.demographic_info;
