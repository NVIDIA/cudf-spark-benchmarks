
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(LOWER(c.c_email_address), 'noemail@domain.com') AS email,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cd.cd_purchase_estimate DESC) AS year_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
)
SELECT 
    full_name,
    email,
    d_year,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate
FROM 
    RankedCustomers
WHERE 
    year_rank <= 10
ORDER BY 
    d_year, cd_purchase_estimate DESC;
