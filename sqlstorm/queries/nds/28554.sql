
WITH AddressString AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                   THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city, 
        ca_state,
        ca_address_sk
    FROM customer_address
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_college_count) AS college_dependents
    FROM customer_demographics
    GROUP BY cd_gender
),
AddressCount AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        d.cd_gender,
        COUNT(*) AS customer_count
    FROM AddressString a
    JOIN customer c ON c.c_current_addr_sk = a.ca_address_sk
    JOIN customer_demographics d ON d.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY a.full_address, a.ca_city, a.ca_state, d.cd_gender
)
SELECT 
    ac.full_address,
    ac.ca_city,
    ac.ca_state,
    ac.cd_gender,
    ac.customer_count,
    ds.gender_count AS demographic_count,
    ds.total_dependents,
    ds.college_dependents
FROM AddressCount ac
JOIN DemographicSummary ds ON ac.cd_gender = ds.cd_gender
ORDER BY ac.ca_city, ac.customer_count DESC;
