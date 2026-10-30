
WITH SplitAddress AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        SPLIT_PART(ca_street_name, ' ', 1) AS first_word,
        SPLIT_PART(ca_street_name, ' ', 2) AS second_word,
        LENGTH(ca_street_name) AS street_name_length
    FROM
        customer_address
),
AggregatedStats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        AVG(street_name_length) AS avg_street_length,
        COUNT(DISTINCT first_word) AS unique_first_words,
        COUNT(DISTINCT second_word) AS unique_second_words
    FROM
        SplitAddress
    GROUP BY
        ca_state
)
SELECT
    ca_state,
    address_count,
    avg_street_length,
    unique_first_words,
    unique_second_words,
    CASE 
        WHEN avg_street_length > 20 THEN 'Long Streets' 
        ELSE 'Short Streets' 
    END AS street_length_category
FROM 
    AggregatedStats
ORDER BY 
    avg_street_length DESC, unique_first_words DESC;
