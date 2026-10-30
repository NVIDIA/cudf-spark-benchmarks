
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN c.c_birth_month = 12 THEN 'December'
            WHEN c.c_birth_month = 1 THEN 'January'
            WHEN c.c_birth_month = 2 THEN 'February'
            WHEN c.c_birth_month = 3 THEN 'March'
            WHEN c.c_birth_month = 4 THEN 'April'
            WHEN c.c_birth_month = 5 THEN 'May'
            WHEN c.c_birth_month = 6 THEN 'June'
            WHEN c.c_birth_month = 7 THEN 'July'
            WHEN c.c_birth_month = 8 THEN 'August'
            WHEN c.c_birth_month = 9 THEN 'September'
            WHEN c.c_birth_month = 10 THEN 'October'
            WHEN c.c_birth_month = 11 THEN 'November'
        END AS birth_month,
        cd.cd_purchase_estimate,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
ranked_customers AS (
    SELECT 
        ci.*,
        ROW_NUMBER() OVER (PARTITION BY ci.ca_state ORDER BY ci.cd_purchase_estimate DESC) AS state_rank
    FROM 
        customer_info ci
)
SELECT 
    r.full_name,
    r.ca_city,
    r.ca_state,
    r.ca_country,
    r.cd_gender,
    r.birth_month,
    r.cd_purchase_estimate,
    r.name_length
FROM 
    ranked_customers r
WHERE 
    r.state_rank <= 5
ORDER BY 
    r.ca_state, r.cd_purchase_estimate DESC;
