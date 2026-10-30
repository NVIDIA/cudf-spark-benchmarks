
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
FilteredAddresses AS (
    SELECT 
        ca.ca_city, 
        ca.ca_state, 
        ca.address_count
    FROM 
        CustomerAddresses ca
    WHERE 
        ca.address_count > 1
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    fa.ca_city,
    fa.ca_state
FROM 
    RankedCustomers rc
JOIN 
    FilteredAddresses fa ON rc.rank <= 5
ORDER BY 
    rc.cd_gender, rc.c_last_name, rc.c_first_name;
