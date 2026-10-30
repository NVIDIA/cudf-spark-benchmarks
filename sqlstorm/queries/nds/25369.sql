
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        RANK() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) AS rnk
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city AS customer_city,
        ca.ca_state AS customer_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DistinctCount AS (
    SELECT 
        customer_state,
        COUNT(DISTINCT customer_city) AS distinct_cities
    FROM 
        CustomerInfo
    GROUP BY 
        customer_state
),
TopAddresses AS (
    SELECT 
        r.ca_address_sk,
        r.ca_street_name,
        r.ca_city,
        r.ca_state,
        d.distinct_cities
    FROM 
        RankedAddresses r
    JOIN 
        DistinctCount d ON r.ca_state = d.customer_state
    WHERE 
        rnk <= 5
)
SELECT 
    ta.ca_address_sk,
    ta.ca_street_name,
    ta.ca_city,
    ta.ca_state,
    ta.distinct_cities
FROM 
    TopAddresses ta
ORDER BY 
    ta.ca_state, ta.distinct_cities DESC;
