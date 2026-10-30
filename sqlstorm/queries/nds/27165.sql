
WITH FilteredCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        UPPER(cd.cd_gender) = 'F' 
        AND cd.cd_marital_status = 'M'
),

AggregatedData AS (
    SELECT 
        SUBSTRING(ca.ca_street_name, 1, 10) AS street_name_short,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS customer_count,
        AVG(cd.cd_dep_count) AS avg_dependents
    FROM 
        FilteredCustomers AS fc
    JOIN 
        customer_demographics AS cd ON fc.c_customer_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON fc.c_customer_sk = ca.ca_address_sk
    GROUP BY 
        SUBSTRING(ca.ca_street_name, 1, 10), 
        ca.ca_city, 
        ca.ca_state
)

SELECT 
    street_name_short,
    ca_city,
    ca_state,
    customer_count,
    avg_dependents,
    CONCAT('City: ', ca_city, ', State: ', ca_state, ', Customers: ', customer_count) AS info
FROM 
    AggregatedData
ORDER BY 
    customer_count DESC
LIMIT 10;
