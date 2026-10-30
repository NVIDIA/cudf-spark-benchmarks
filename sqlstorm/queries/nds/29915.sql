
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressCount AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_city
),
TopCities AS (
    SELECT 
        ac.ca_city,
        ac.address_count,
        ROW_NUMBER() OVER (ORDER BY ac.address_count DESC) AS city_rank
    FROM 
        AddressCount ac
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    tc.ca_city,
    tc.address_count
FROM 
    RankedCustomers rc
JOIN 
    TopCities tc ON rc.c_customer_id LIKE '%' || tc.ca_city || '%'
WHERE 
    rc.rank <= 5 AND 
    tc.city_rank <= 10
ORDER BY 
    rc.cd_gender, rc.cd_purchase_estimate DESC;
