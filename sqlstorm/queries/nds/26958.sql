
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) AS street_number,
        TRIM(ca_street_name) AS street_name,
        TRIM(ca_street_type) AS street_type,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
FullCustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_year AS full_birth_year,
        a.street_number,
        a.street_name,
        a.street_type,
        a.city,
        a.state,
        a.zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        AddressComponents a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
AgeDistribution AS (
    SELECT 
        EXTRACT(YEAR FROM DATE '2002-10-01') - full_birth_year AS age,
        COUNT(*) AS num_customers
    FROM 
        FullCustomerInfo
    GROUP BY 
        age
),
ZipAnalysis AS (
    SELECT 
        zip,
        COUNT(*) AS num_customers,
        COUNT(DISTINCT full_name) AS unique_customers,
        COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_count,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count
    FROM 
        FullCustomerInfo
    GROUP BY 
        zip
)

SELECT 
    zd.zip,
    zd.num_customers,
    zd.unique_customers,
    zd.male_count,
    zd.female_count,
    AVG(ad.age) AS avg_age
FROM 
    ZipAnalysis zd
LEFT JOIN 
    AgeDistribution ad ON ad.age < 100  
GROUP BY 
    zd.zip, zd.num_customers, zd.unique_customers, zd.male_count, zd.female_count
ORDER BY 
    zd.num_customers DESC
LIMIT 50;
