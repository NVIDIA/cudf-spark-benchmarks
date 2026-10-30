
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) || 
        CASE 
            WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN ' Suite ' || TRIM(ca_suite_number) 
            ELSE '' 
        END AS full_address,
        ca_city,
        ca_state
    FROM
        customer_address
), 
word_count AS (
    SELECT
        ca_address_sk,
        LENGTH(full_address) - LENGTH(REPLACE(full_address, ' ', '')) + 1 AS word_count
    FROM
        processed_addresses
),
top_cities AS (
    SELECT
        ca_city,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM
        processed_addresses
    GROUP BY
        ca_city
    HAVING
        COUNT(DISTINCT ca_address_sk) > 5
)
SELECT 
    pa.ca_address_sk,
    pa.full_address,
    wc.word_count,
    tc.ca_city,
    tc.address_count
FROM 
    processed_addresses pa
JOIN 
    word_count wc ON pa.ca_address_sk = wc.ca_address_sk
JOIN 
    top_cities tc ON pa.ca_city = tc.ca_city
WHERE 
    wc.word_count > 3
ORDER BY 
    tc.address_count DESC, wc.word_count DESC;
