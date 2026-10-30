
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    COALESCE(CONCAT(' ', ca_suite_number), ''))) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper,
        LEFT(ca_zip, 5) AS zip_prefix
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        INITCAP(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        address_parts.full_address,
        address_parts.city_lower,
        address_parts.state_upper,
        address_parts.zip_prefix
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    JOIN 
        address_parts ON c.c_current_addr_sk = address_parts.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    cd_credit_rating,
    cd_dep_count,
    full_address,
    city_lower,
    state_upper,
    zip_prefix,
    COUNT(*) OVER (PARTITION BY city_lower, state_upper) AS count_in_location
FROM 
    customer_info
WHERE 
    cd_purchase_estimate > 1000 AND 
    city_lower LIKE 'a%' AND 
    state_upper IN ('NY', 'CA')
ORDER BY 
    cd_purchase_estimate DESC, 
    full_name;
