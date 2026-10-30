
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', 
               TRIM(ca_street_type), COALESCE(CONCAT(' Suite ', TRIM(ca_suite_number)), '')) AS full_address,
        LOWER(TRIM(ca_city)) AS normalized_city,
        UPPER(TRIM(ca_state)) AS normalized_state
    FROM customer_address
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        pa.full_address,
        pa.normalized_city,
        pa.normalized_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN processed_addresses pa ON c.c_current_addr_sk = pa.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    normalized_city,
    COUNT(*) AS customer_count
FROM customer_info
WHERE 
    normalized_state IN ('CA', 'TX', 'NY') 
    AND cd_marital_status IN ('M', 'S')
GROUP BY 
    full_name, cd_gender, cd_marital_status, cd_education_status, normalized_city
HAVING 
    COUNT(*) > 1
ORDER BY 
    customer_count DESC, full_name ASC
LIMIT 100;
