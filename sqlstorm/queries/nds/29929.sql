
WITH AddressStats AS (
    SELECT 
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        SUM(CASE WHEN ca_state = 'CA' THEN 1 ELSE 0 END) AS california_count
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
    GROUP BY 
        ca_city, ca_street_number, ca_street_name, ca_street_type
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.full_address,
    a.street_name_length,
    a.city_length,
    a.california_count,
    c.cd_gender,
    c.customer_count,
    c.average_purchase_estimate
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON LENGTH(a.ca_city) = LENGTH(c.cd_gender)
WHERE 
    a.city_length > 5
ORDER BY 
    a.california_count DESC, c.customer_count DESC;
