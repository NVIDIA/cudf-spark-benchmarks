
WITH AddressStats AS (
    SELECT 
        SUBSTRING(ca_street_name, 1, 10) AS street_prefix,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_length,
        MAX(LENGTH(ca_street_name)) AS max_street_length,
        MIN(LENGTH(ca_street_name)) AS min_street_length
    FROM 
        customer_address 
    GROUP BY 
        SUBSTRING(ca_street_name, 1, 10)
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
DetailedStats AS (
    SELECT 
        a.street_prefix,
        a.address_count,
        a.avg_street_length,
        a.max_street_length,
        a.min_street_length,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.customer_count
    FROM 
        AddressStats a
    JOIN 
        Demographics d ON a.address_count >= d.customer_count
)
SELECT 
    street_prefix,
    SUM(customer_count) AS total_customers,
    AVG(avg_street_length) AS average_street_length,
    MAX(max_street_length) AS longest_street,
    MIN(min_street_length) AS shortest_street
FROM 
    DetailedStats
GROUP BY 
    street_prefix 
ORDER BY 
    street_prefix;
