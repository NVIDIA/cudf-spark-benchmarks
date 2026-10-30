
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        (SELECT COUNT(*) 
         FROM customer 
         WHERE c_current_addr_sk = ca_address_sk) AS customer_count
    FROM 
        customer_address
),
TopCities AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_count
    FROM 
        AddressInfo
    GROUP BY 
        ca_city
    ORDER BY 
        city_count DESC
    LIMIT 5
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
FinalBenchmark AS (
    SELECT 
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        tc.city_count,
        dm.cd_gender,
        dm.cd_marital_status,
        dm.cd_education_status,
        dm.demographic_count
    FROM 
        AddressInfo ai
    JOIN 
        TopCities tc ON ai.ca_city = tc.ca_city
    JOIN 
        Demographics dm ON 1=1
)
SELECT 
    CONCAT(full_address, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS Address,
    city_count AS Number_of_Customers_in_City,
    cd_gender AS Gender,
    cd_marital_status AS Marital_Status,
    cd_education_status AS Education_Status,
    demographic_count AS Number_of_Customers_in_Demographic_Group
FROM 
    FinalBenchmark
ORDER BY 
    city_count DESC, demographic_count DESC;
