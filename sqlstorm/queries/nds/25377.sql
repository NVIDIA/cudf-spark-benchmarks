WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AgeDistribution AS (
    SELECT 
        EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year AS age,
        COUNT(*) AS count
    FROM 
        CustomerInfo
    GROUP BY 
        age
),
LocationCount AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS customer_count
    FROM 
        CustomerInfo
    GROUP BY 
        ca_state, ca_city
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        CustomerInfo
    GROUP BY 
        cd_gender
)
SELECT 
    a.age,
    a.count AS age_distribution_count,
    l.ca_state,
    l.ca_city,
    l.customer_count,
    g.cd_gender,
    g.gender_count
FROM 
    AgeDistribution a
FULL OUTER JOIN 
    LocationCount l ON true
FULL OUTER JOIN 
    GenderStats g ON true
ORDER BY 
    a.age, l.ca_state, l.ca_city, g.cd_gender;