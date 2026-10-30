
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        RANK() OVER (PARTITION BY cd.cd_marital_status, cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TrimmedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ' ', TRIM(ca.ca_street_type), 
               COALESCE(CONCAT(' Suite ', TRIM(ca.ca_suite_number)), '')) AS full_address
    FROM 
        customer_address ca
),
FilteredCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        ta.full_address
    FROM 
        RankedCustomers rc
    JOIN 
        TrimmedAddresses ta ON rc.c_customer_sk = ta.ca_address_sk
    WHERE 
        rc.rank <= 10
)
SELECT 
    fc.full_name,
    fc.cd_gender,
    fc.cd_marital_status,
    COUNT(*) OVER (PARTITION BY fc.cd_gender, fc.cd_marital_status) AS gender_marital_count,
    fc.full_address
FROM 
    FilteredCustomers fc
ORDER BY 
    fc.cd_marital_status, 
    fc.cd_gender, 
    fc.full_name;
