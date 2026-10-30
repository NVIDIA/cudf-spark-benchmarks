
WITH processed_data AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr.'
            WHEN cd.cd_gender = 'F' THEN 'Ms.'
            ELSE 'Mx.'
        END AS salutation,
        LEFT(REPLACE(LOWER(ca.ca_street_name), ' ', ''), 10) AS street_name_key,
        LENGTH(ca.ca_zip) AS zip_length,
        TRIM(REGEXP_REPLACE(ca.ca_street_number, '[^0-9]', '')) AS numeric_street_number,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
aggregate_results AS (
    SELECT 
        salutation,
        COUNT(*) AS total_customers,
        AVG(zip_length) AS avg_zip_length,
        COUNT(DISTINCT street_name_key) AS unique_street_names,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
    FROM 
        processed_data
    GROUP BY 
        salutation
)
SELECT 
    salutation,
    total_customers,
    avg_zip_length,
    unique_street_names,
    married_count,
    single_count,
    CONCAT(salutation, ' ', 'Total: ', total_customers, ', Avg Zip Length: ', avg_zip_length) AS summary_report
FROM 
    aggregate_results
ORDER BY 
    total_customers DESC;
