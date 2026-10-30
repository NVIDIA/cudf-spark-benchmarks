
WITH string_benchmarking AS (
    SELECT
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        LOWER(c.c_email_address) AS email_lower,
        UPPER(c.c_login) AS login_upper,
        LENGTH(ca.ca_street_name) AS street_name_length,
        REGEXP_REPLACE(ca.ca_street_name, '[^a-zA-Z]', '') AS street_name_alpha_only,
        SUBSTR(ca.ca_zip, 1, 5) AS zip_prefix,
        CHAR_LENGTH(ca.ca_country) AS country_length
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
),
summary AS (
    SELECT
        ca_state,
        COUNT(*) AS customers_count,
        AVG(street_name_length) AS avg_street_name_length,
        MIN(LENGTH(full_name)) AS min_full_name_length,
        MAX(LENGTH(full_name)) AS max_full_name_length,
        COUNT(DISTINCT email_lower) AS unique_email_count,
        SUM(CASE WHEN country_length > 10 THEN 1 ELSE 0 END) AS long_country_names
    FROM string_benchmarking
    GROUP BY ca_state
)
SELECT 
    ca_state,
    customers_count,
    avg_street_name_length,
    min_full_name_length,
    max_full_name_length,
    unique_email_count,
    long_country_names,
    CONCAT('State ', ca_state, ' has ', customers_count, ' customers with an average street name length of ', avg_street_name_length) AS summary_message
FROM summary
ORDER BY customers_count DESC;
