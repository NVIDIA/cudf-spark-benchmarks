
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
        COALESCE(ib.ib_upper_bound, 0) AS income_upper_bound,
        ad.full_address,
        ad.ca_city AS city,
        ad.ca_state AS state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN 
        AddressDetails ad ON ad.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    COUNT(*) AS total_customers,
    cd.gender,
    cd.marital_status,
    MIN(cd.income_lower_bound) AS min_income,
    MAX(cd.income_upper_bound) AS max_income,
    COUNT(DISTINCT cd.full_name) AS unique_customers,
    COUNT(DISTINCT CONCAT(cd.full_name, ' - ', cd.full_address)) AS unique_customer_addresses,
    cd.city,
    cd.state
FROM 
    CustomerDetails cd
GROUP BY 
    cd.gender, cd.marital_status, cd.city, cd.state
ORDER BY 
    total_customers DESC;
