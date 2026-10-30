
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_country AS customer_country,
        ca.ca_city AS customer_city,
        ca.ca_zip AS customer_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCities AS (
    SELECT 
        customer_city,
        COUNT(*) AS city_population
    FROM 
        CustomerInfo
    GROUP BY 
        customer_city
    ORDER BY 
        city_population DESC
    LIMIT 10
)
SELECT 
    ci.full_customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.customer_country,
    ci.customer_city,
    ci.customer_zip,
    tc.city_population
FROM 
    CustomerInfo ci
JOIN 
    TopCities tc ON ci.customer_city = tc.customer_city
ORDER BY 
    tc.city_population DESC, ci.full_customer_name;
