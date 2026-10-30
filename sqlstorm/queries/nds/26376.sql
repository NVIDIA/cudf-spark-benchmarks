
WITH concatenated_names AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_customer_sk AS customer_id,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_zip AS zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'M'
        AND ca.ca_state IN ('CA', 'NY', 'TX')
),
string_length_analysis AS (
    SELECT 
        full_name,
        LENGTH(full_name) AS name_length,
        city,
        state,
        zip
    FROM 
        concatenated_names
)
SELECT 
    city,
    state,
    COUNT(*) AS total_customers,
    AVG(name_length) AS average_name_length
FROM 
    string_length_analysis
GROUP BY 
    city, state
ORDER BY 
    total_customers DESC, average_name_length DESC;
