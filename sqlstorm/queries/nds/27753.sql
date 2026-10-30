
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
formatted_benchmark AS (
    SELECT 
        c.c_customer_sk,
        UPPER(c.full_name) AS upper_full_name,
        LOWER(c.full_name) AS lower_full_name,
        LENGTH(c.full_name) AS full_name_length,
        REPLACE(c.ca_city, ' ', '_') AS city_replaced,
        CASE 
            WHEN LENGTH(c.ca_state) < 3 THEN 'Short State' 
            ELSE 'Long State' 
        END AS state_length_category
    FROM 
        customer_info c
),
aggregated_results AS (
    SELECT 
        fb.state_length_category,
        COUNT(*) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        formatted_benchmark fb
    JOIN 
        customer_demographics cd ON fb.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        fb.state_length_category
)
SELECT 
    *
FROM 
    aggregated_results
ORDER BY 
    customer_count DESC;
