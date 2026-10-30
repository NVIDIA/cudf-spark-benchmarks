
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_zip,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address
    LEFT JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type, ca_zip
),
TopCities AS (
    SELECT
        ca_city,
        ca_state,
        SUM(customer_count) AS total_customers
    FROM 
        AddressDetails
    GROUP BY 
        ca_city, ca_state
    ORDER BY 
        total_customers DESC
    LIMIT 10
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.full_address,
    a.customer_count,
    t.total_customers
FROM 
    AddressDetails a
JOIN 
    TopCities t ON a.ca_city = t.ca_city AND a.ca_state = t.ca_state
ORDER BY 
    t.total_customers DESC, a.customer_count DESC;
