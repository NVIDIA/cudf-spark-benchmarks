
WITH Ranked_Addresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        LOWER(ca_street_name) AS street_name_lower,
        LENGTH(ca_street_name) AS street_name_length,
        ROW_NUMBER() OVER (PARTITION BY ca_country ORDER BY ca_city, ca_street_name) AS rn
    FROM 
        customer_address
),
Filtered_Addresses AS (
    SELECT 
        *,
        CASE 
            WHEN street_name_length > 20 THEN 'Long Street Name' 
            ELSE 'Short Street Name' 
        END AS street_name_category
    FROM 
        Ranked_Addresses
    WHERE 
        rn <= 100
),
Aggregate_Stats AS (
    SELECT 
        ca_country,
        street_name_category,
        COUNT(*) AS address_count,
        AVG(street_name_length) AS avg_length
    FROM 
        Filtered_Addresses
    GROUP BY 
        ca_country, street_name_category
)

SELECT 
    ca_country,
    street_name_category,
    address_count,
    avg_length,
    CONCAT('In ', ca_country, ', there are ', address_count, ' addresses classified as ', street_name_category, ' with an average length of ', ROUND(avg_length, 2), ' characters.') AS summary
FROM 
    Aggregate_Stats
ORDER BY 
    ca_country, street_name_category;
