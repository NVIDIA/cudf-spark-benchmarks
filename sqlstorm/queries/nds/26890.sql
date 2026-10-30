
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count,
        CONCAT(ca_city, ', ', ca_state) AS city_state,
        SUM(LENGTH(ca_street_name)) AS total_street_length
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
DemographicCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demo_count,
        AVG(cd_dep_count) AS avg_dep_count 
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
FinalBenchmark AS (
    SELECT 
        a.ca_state,
        a.city_state,
        a.address_count,
        a.total_street_length,
        d.cd_gender,
        d.demo_count,
        d.avg_dep_count,
        CONCAT(a.city_state, ' has ', a.address_count, ' addresses with a combined street length of ', a.total_street_length, 
               ' characters and ', d.demo_count, ' demographics of gender ', d.cd_gender, 
               ' with an average dependents count of ', d.avg_dep_count) AS benchmark_summary
    FROM 
        AddressCounts a
    JOIN 
        DemographicCounts d ON a.ca_state IS NOT NULL
)
SELECT 
    benchmark_summary
FROM 
    FinalBenchmark
WHERE 
    address_count > 100 OR demo_count > 50
ORDER BY 
    address_count DESC, demo_count DESC;
