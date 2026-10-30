
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_month IN (SELECT d.d_moy FROM date_dim d WHERE d.d_year = 2023)
),
address_details AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer_address ca
),
customer_address_details AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        ad.ca_zip
    FROM 
        ranked_customers rc
    JOIN 
        customer c ON rc.c_customer_sk = c.c_customer_sk
    JOIN 
        address_details ad ON c.c_current_addr_sk = ad.ca_address_sk
    WHERE 
        rc.rank <= 10
)
SELECT 
    cad.c_first_name,
    cad.c_last_name,
    cad.cd_gender,
    cad.cd_marital_status,
    cad.cd_education_status,
    cad.ca_city,
    cad.ca_state,
    cad.ca_country,
    cad.ca_zip
FROM 
    customer_address_details cad
WHERE 
    cad.cd_gender = 'F'
ORDER BY 
    cad.c_last_name ASC, cad.c_first_name ASC;
