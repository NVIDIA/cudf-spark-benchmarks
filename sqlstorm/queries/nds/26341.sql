
WITH Address_Analysis AS (
    SELECT 
        ca_address_sk,
        LOWER(ca_city) AS lower_city,
        UPPER(ca_street_name) AS upper_street_name,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REGEXP_REPLACE(ca_zip, '[^0-9]', '') AS cleaned_zip
    FROM 
        customer_address
),
Filtered_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.lower_city,
        a.upper_street_name,
        a.street_name_length,
        a.full_address,
        a.cleaned_zip,
        d.d_year
    FROM 
        customer c
    JOIN 
        Address_Analysis a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        a.lower_city LIKE 'san%'
        AND a.street_name_length > 5
        AND d.d_year >= 2020
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS customer_full_name,
    lower_city,
    full_address,
    cleaned_zip,
    COUNT(*) OVER (PARTITION BY lower_city) AS city_customer_count
FROM 
    Filtered_Customers
ORDER BY 
    lower_city, customer_full_name;
