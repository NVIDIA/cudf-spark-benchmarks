
WITH CustomerCity AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city AS city,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), AggregatedCityData AS (
    SELECT 
        city,
        state,
        COUNT(*) AS customer_count,
        SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
        SUM(CASE WHEN marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM 
        CustomerCity
    GROUP BY 
        city, state
), RankedCityData AS (
    SELECT 
        city,
        state,
        customer_count,
        female_count,
        male_count,
        single_count,
        married_count,
        DENSE_RANK() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM 
        AggregatedCityData
)
SELECT 
    city,
    state,
    customer_count,
    female_count,
    male_count,
    single_count,
    married_count,
    city_rank
FROM 
    RankedCityData
WHERE 
    city_rank <= 10
ORDER BY 
    customer_count DESC;
