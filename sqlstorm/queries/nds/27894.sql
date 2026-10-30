
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CASE 
            WHEN ca.ca_country = 'USA' THEN 'Domestic' 
            ELSE 'International' 
        END AS address_type
    FROM 
        customer_address ca
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN cd.cd_dep_count > 0 THEN 1 ELSE 0 END) AS dependents_count,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(DISTINCT ca.ca_address_sk) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cm.customer_name,
    cm.cd_gender,
    cm.cd_marital_status,
    cm.dependents_count,
    ad.full_address,
    ad.address_type,
    cm.gender_rank
FROM 
    CustomerMetrics cm
JOIN 
    AddressDetails ad ON cm.c_customer_sk = ad.ca_address_sk
WHERE 
    ad.address_type = 'Domestic'
ORDER BY 
    cm.gender_rank, cm.customer_name;
