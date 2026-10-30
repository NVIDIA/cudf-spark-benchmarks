
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (
            PARTITION BY ca_state 
            ORDER BY LENGTH(ca_street_name) DESC, ca_city ASC
        ) AS rnk
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
FilteredAddresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT('Street: ', ca_street_name, ', City: ', ca_city, ', State: ', ca_state) AS full_address
    FROM 
        RankedAddresses
    WHERE 
        rnk <= 5
)
SELECT 
    fa.full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(c.c_customer_sk) AS customer_count
FROM 
    FilteredAddresses fa
JOIN 
    customer c ON fa.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    fa.full_address, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    customer_count DESC;
