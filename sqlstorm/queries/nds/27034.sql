WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) as RankByGender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS FullAddress
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'NY')
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    fa.ca_city,
    fa.FullAddress
FROM 
    RankedCustomers rc
JOIN 
    FilteredAddresses fa ON fa.ca_address_sk = rc.c_customer_sk  
WHERE 
    rc.RankByGender <= 5
ORDER BY 
    rc.cd_gender, rc.RankByGender;