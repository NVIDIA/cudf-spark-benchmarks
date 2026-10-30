
WITH AddressDetail AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
DemographicDetail AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        REPLACE(cd_education_status, ' ', '-') AS formatted_education,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
CustomerDetail AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ad.full_address,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.formatted_education,
        dd.cd_purchase_estimate 
    FROM 
        customer c
        JOIN AddressDetail ad ON c.c_current_addr_sk = ad.ca_address_sk
        JOIN DemographicDetail dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
),
RankedCustomers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS purchase_rank 
    FROM 
        CustomerDetail
)
SELECT 
    full_name,
    full_address,
    cd_gender,
    cd_marital_status,
    formatted_education,
    cd_purchase_estimate
FROM 
    RankedCustomers
WHERE 
    purchase_rank <= 5 
    AND cd_marital_status IN ('M', 'S')
ORDER BY 
    cd_gender, purchase_rank;
