
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS city_state_zip,
        ca.ca_country,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
address_summary AS (
    SELECT 
        ci.city_state_zip, 
        COUNT(*) AS customer_count,
        MIN(ci.value_category) AS lowest_value_category,
        MAX(ci.value_category) AS highest_value_category
    FROM 
        customer_info ci
    GROUP BY 
        ci.city_state_zip
)
SELECT 
    asu.city_state_zip,
    asu.customer_count,
    asu.lowest_value_category,
    asu.highest_value_category,
    CASE 
        WHEN asu.customer_count > 100 THEN 'Busy Area'
        WHEN asu.customer_count BETWEEN 50 AND 100 THEN 'Moderate Area'
        ELSE 'Quiet Area'
    END AS area_activity
FROM 
    address_summary asu
ORDER BY 
    asu.customer_count DESC, 
    asu.city_state_zip;
