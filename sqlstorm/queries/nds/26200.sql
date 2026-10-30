
WITH CustomerFullName AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', 
               ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
UniqueCities AS (
    SELECT DISTINCT
        ca_city
    FROM 
        customer_address
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    c.full_name,
    a.full_address,
    COALESCE(s.total_spent, 0) AS total_spent,
    (SELECT COUNT(*) FROM UniqueCities) AS total_unique_cities
FROM 
    CustomerFullName c
JOIN 
    AddressDetails a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.customer_sk
WHERE 
    total_spent > 1000
ORDER BY 
    total_spent DESC
LIMIT 10;
