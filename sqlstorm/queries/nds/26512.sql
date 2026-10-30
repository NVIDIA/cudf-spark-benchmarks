
WITH RankedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city, ca.ca_state ORDER BY ca.ca_address_sk) AS addr_rank
    FROM 
        customer_address ca
    WHERE 
        LENGTH(ca.ca_street_name) > 10
),
FilteredDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ra.ca_address_sk) AS address_count
    FROM 
        customer_demographics cd
    JOIN 
        RankedAddresses ra ON cd.cd_demo_sk = ra.ca_address_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, cd.cd_credit_rating
)
SELECT 
    fd.cd_gender,
    fd.cd_marital_status,
    fd.cd_education_status,
    AVG(fd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(fd.address_count) AS total_unique_addresses
FROM 
    FilteredDemographics fd
WHERE 
    fd.cd_credit_rating LIKE 'Good%'
GROUP BY 
    fd.cd_gender, fd.cd_marital_status, fd.cd_education_status
ORDER BY 
    fd.cd_gender, fd.cd_marital_status;
