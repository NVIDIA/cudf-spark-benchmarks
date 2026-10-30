
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
address_count AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk
),
filtered_customers AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.full_address,
        ac.customer_count
    FROM 
        customer_data cd
    JOIN 
        address_count ac ON cd.c_customer_id IN (
            SELECT 
                c.c_customer_id 
            FROM 
                customer c 
            WHERE 
                c.c_current_addr_sk IN (
                    SELECT 
                        ca.ca_address_sk 
                    FROM 
                        customer_address ca 
                    WHERE 
                        ca.ca_state = 'CA'
                )
        )
    WHERE 
        cd.cd_gender = 'F' 
        AND ac.customer_count > 10
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    full_address
FROM 
    filtered_customers
ORDER BY 
    cd_gender, cd_marital_status, ca_city;
