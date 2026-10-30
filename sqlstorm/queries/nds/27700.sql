
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1, 50) AS domain_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FrequentDomains AS (
    SELECT 
        domain_name,
        COUNT(*) AS domain_count
    FROM 
        CustomerDetails
    GROUP BY 
        domain_name
    HAVING 
        COUNT(*) > 5
),
AggregateData AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ca_city,
        cd.ca_state,
        fd.domain_name
    FROM 
        CustomerDetails cd
    JOIN 
        FrequentDomains fd ON cd.domain_name = fd.domain_name
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    COUNT(*) OVER(PARTITION BY ca_state ORDER BY full_name) AS count_in_state,
    domain_name
FROM 
    AggregateData
ORDER BY 
    ca_state, full_name;
