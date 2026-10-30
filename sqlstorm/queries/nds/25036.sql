
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        CONCAT(ca_city, ', ', ca_state) AS location
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
TopCities AS (
    SELECT 
        location, 
        address_count, 
        ROW_NUMBER() OVER (ORDER BY address_count DESC) AS city_rank
    FROM 
        AddressCounts
    WHERE 
        address_count >= 50
),
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(c.c_customer_sk) AS customer_count, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    T.city_rank, 
    T.location, 
    T.address_count, 
    CS.cd_gender, 
    CS.customer_count, 
    CS.avg_purchase_estimate, 
    CS.avg_dep_count
FROM 
    TopCities T
JOIN 
    CustomerStats CS ON T.city_rank <= 5 
ORDER BY 
    T.city_rank;
