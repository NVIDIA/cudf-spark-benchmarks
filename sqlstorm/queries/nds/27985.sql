
WITH AddressInfo AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_city, ca.ca_state, ca.ca_country
),
DemographicInfo AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cd.cd_dep_count) AS total_dependencies,
        SUM(cd.cd_dep_employed_count) AS total_employed_dependencies
    FROM customer_demographics cd
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
StringProcessing AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        CONCAT(a.ca_city, ', ', a.ca_state, ', ', a.ca_country) AS full_address,
        LENGTH(CONCAT(a.ca_city, ', ', a.ca_state, ', ', a.ca_country)) AS address_length,
        LENGTH(d.cd_marital_status) AS marital_status_length,
        CONCAT(d.cd_gender, '-', d.cd_marital_status) AS demographic_string
    FROM AddressInfo a
    JOIN DemographicInfo d ON a.customer_count > 0
)
SELECT 
    full_address,
    address_length,
    marital_status_length,
    demographic_string,
    COUNT(*) AS record_count
FROM StringProcessing
GROUP BY full_address, address_length, marital_status_length, demographic_string
HAVING address_length > 20
ORDER BY address_length DESC, record_count DESC;
