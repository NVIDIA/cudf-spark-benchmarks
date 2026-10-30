
WITH Concatenated AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        d.d_date AS date_value,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
    WHERE
        ca.ca_state = 'CA'
        AND cd.cd_purchase_estimate IS NOT NULL
),
Ranked AS (
    SELECT 
        full_name, 
        ca_city, 
        ca_state, 
        ca_zip, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        date_value,
        RANK() OVER (PARTITION BY ca_city ORDER BY rank) AS city_rank
    FROM 
        Concatenated
)
SELECT 
    full_name, 
    ca_city, 
    ca_state, 
    ca_zip, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    date_value 
FROM 
    Ranked 
WHERE 
    city_rank <= 5 
ORDER BY 
    ca_city, 
    cd_gender;
