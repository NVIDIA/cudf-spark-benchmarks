
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
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
address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        COUNT(DISTINCT full_name) AS unique_names
    FROM 
        customer_info
    GROUP BY 
        ca_city, ca_state
),
gender_stats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_id) AS gender_count
    FROM 
        customer_info
    GROUP BY 
        cd_gender
),
demo_statistics AS (
    SELECT 
        cd_marital_status,
        COUNT(c_customer_id) AS marital_count
    FROM 
        customer_info
    GROUP BY 
        cd_marital_status
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.customer_count,
    a.unique_names,
    g.cd_gender,
    g.gender_count,
    d.cd_marital_status,
    d.marital_count
FROM 
    address_summary a
LEFT JOIN 
    gender_stats g ON a.ca_city IN (SELECT DISTINCT ca_city FROM customer_info)
LEFT JOIN 
    demo_statistics d ON a.ca_city IN (SELECT DISTINCT ca_city FROM customer_info)
ORDER BY 
    a.ca_state, a.customer_count DESC;
