
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rank_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressSummary AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
),
TopCities AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        customer_count,
        unique_addresses,
        RANK() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM 
        AddressSummary ca
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    tc.ca_city,
    tc.ca_state,
    tc.customer_count,
    tc.unique_addresses
FROM 
    RankedCustomers rc
JOIN 
    TopCities tc ON rc.rank_gender <= 10 AND tc.city_rank <= 5
ORDER BY 
    tc.customer_count DESC, rc.c_last_name, rc.c_first_name;
