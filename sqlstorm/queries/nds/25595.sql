
WITH customer_info AS (
    SELECT 
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
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
),
address_info AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_city, ca.ca_state
),
web_info AS (
    SELECT 
        wp.wp_type,
        COUNT(*) AS page_count,
        SUM(wp.wp_char_count) AS total_chars
    FROM 
        web_page wp
    GROUP BY 
        wp.wp_type
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ai.address_count,
    wi.page_count,
    wi.total_chars
FROM 
    customer_info ci
LEFT JOIN 
    address_info ai ON ci.ca_city = ai.ca_city AND ci.ca_state = ai.ca_state
LEFT JOIN 
    web_info wi ON ci.cd_gender = 'F' AND ci.cd_marital_status = 'M'
WHERE 
    ci.cd_purchase_estimate > 5000
ORDER BY 
    ci.cd_purchase_estimate DESC;
