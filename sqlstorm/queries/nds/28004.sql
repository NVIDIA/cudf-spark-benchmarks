
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
TopStates AS (
    SELECT 
        ca_state,
        address_count
    FROM 
        AddressCounts
    ORDER BY 
        address_count DESC
    LIMIT 5
),
TopGenders AS (
    SELECT 
        cd_gender,
        customer_count
    FROM 
        CustomerCounts
    ORDER BY 
        customer_count DESC
    LIMIT 5
),
Combined AS (
    SELECT 
        t.ca_state,
        t.address_count,
        g.cd_gender,
        g.customer_count
    FROM 
        TopStates t
    CROSS JOIN 
        TopGenders g
)
SELECT 
    ca_state,
    address_count,
    cd_gender,
    customer_count,
    CONCAT('State: ', ca_state, ' has ', address_count, ' addresses; ', 'Gender: ', cd_gender, ' has ', customer_count, ' customers.') AS description
FROM 
    Combined
ORDER BY 
    address_count DESC, customer_count DESC;
