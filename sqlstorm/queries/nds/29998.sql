WITH ProcessedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_review_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CA.ca_city,
        CA.ca_state,
        SUBSTRING(CA.ca_zip, 1, 5) AS zip_prefix,
        LENGTH(CA.ca_street_name) AS street_name_length,
        UPPER(CA.ca_street_type) AS street_type_upper
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
    JOIN 
        date_dim d ON c.c_last_review_date_sk = d.d_date_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
        AND d.d_date < cast('2002-10-01' as date)
), FilteredCustomers AS (
    SELECT 
        *,
        CASE
            WHEN cd_gender = 'M' THEN 'Mr.'
            WHEN cd_gender = 'F' THEN 'Ms.'
            ELSE 'Mx.'
        END AS salutation
    FROM 
        ProcessedCustomers
    WHERE 
        cd_marital_status = 'M'
        AND cd_purchase_estimate > 500
)

SELECT 
    salutation,
    full_name,
    last_review_date,
    cd_gender,
    cd_purchase_estimate,
    ca_city,
    ca_state,
    zip_prefix,
    street_name_length,
    street_type_upper
FROM 
    FilteredCustomers
ORDER BY 
    cd_purchase_estimate DESC
LIMIT 100;