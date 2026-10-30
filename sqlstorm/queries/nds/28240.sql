WITH AddressCounts AS (
    SELECT 
        ca_city, 
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
TopCities AS (
    SELECT 
        ca_city,
        address_count,
        ROW_NUMBER() OVER (ORDER BY address_count DESC) AS rn
    FROM 
        AddressCounts
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CityCustomerCount AS (
    SELECT 
        tc.ca_city,
        COUNT(ci.c_customer_id) AS customer_count
    FROM 
        TopCities tc
    LEFT JOIN 
        CustomerInfo ci ON 1=1  
    WHERE 
        tc.rn <= 10  
    GROUP BY 
        tc.ca_city
)
SELECT 
    ca.ca_city,
    ca.address_count,
    ccc.customer_count
FROM 
    TopCities ca
JOIN 
    CityCustomerCount ccc ON ca.ca_city = ccc.ca_city
WHERE 
    ca.rn <= 10
ORDER BY 
    ca.address_count DESC, ccc.customer_count DESC;