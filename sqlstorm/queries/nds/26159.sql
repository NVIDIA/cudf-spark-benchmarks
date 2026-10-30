
WITH CustomerFullNames AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        full_name,
        c_email_address,
        c_birth_country,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c_birth_country ORDER BY cd_purchase_estimate DESC) AS ranking
    FROM 
        CustomerFullNames
    WHERE 
        cd_gender = 'F' AND
        cd_marital_status = 'M' AND 
        cd_purchase_estimate > 5000
),
TopCustomers AS (
    SELECT 
        full_name,
        c_email_address,
        c_birth_country,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        FilteredCustomers
    WHERE 
        ranking <= 10
)
SELECT 
    CONCAT('Customer: ', full_name, ' | Email: ', c_email_address, ' | Country: ', c_birth_country, 
           ' | Gender: ', cd_gender, ' | Marital Status: ', cd_marital_status, 
           ' | Education: ', cd_education_status, ' | Purchase Estimate: $', cd_purchase_estimate) AS CustomerDetails
FROM 
    TopCustomers
ORDER BY 
    c_birth_country, cd_purchase_estimate DESC;
