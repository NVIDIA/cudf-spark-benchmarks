
WITH ParsedAddresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        REPLACE(ca_zip, '-', '') AS normalized_zip
    FROM 
        customer_address
),
CityCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_count
    FROM 
        ParsedAddresses
    GROUP BY 
        ca_city
),
PopularCities AS (
    SELECT 
        ca_city
    FROM 
        CityCounts
    WHERE 
        city_count > (SELECT AVG(city_count) FROM CityCounts)
),
CustomerCityDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        a.full_address,
        a.normalized_zip
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        ParsedAddresses AS a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE 
        a.ca_city IN (SELECT ca_city FROM PopularCities)
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    full_address,
    normalized_zip,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate
FROM 
    CustomerCityDemographics
ORDER BY 
    cd_purchase_estimate DESC
LIMIT 100;
