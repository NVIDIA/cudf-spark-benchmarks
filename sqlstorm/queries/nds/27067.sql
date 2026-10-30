
WITH Address_Processing AS (
    SELECT 
        ca_address_sk,
        LOWER(ca_street_name) AS street_name_lower,
        UPPER(ca_city) AS city_name_upper,
        LENGTH(ca_zip) AS zip_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        SUBSTR(ca_country, 1, 3) AS country_prefix,
        REPLACE(ca_suite_number, ' ', '') AS suite_number_no_spaces
    FROM 
        customer_address
),
Customer_Analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.street_name_lower,
        a.city_name_upper,
        a.zip_length,
        a.full_address,
        a.country_prefix,
        a.suite_number_no_spaces,
        COUNT(wp.wp_web_page_sk) AS accessed_web_pages
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        Address_Processing a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_gender, d.cd_marital_status, 
        d.cd_education_status, a.street_name_lower, a.city_name_upper, a.zip_length, 
        a.full_address, a.country_prefix, a.suite_number_no_spaces
)
SELECT 
    ca.*,
    CASE 
        WHEN accessed_web_pages > 5 THEN 'Frequent Web User'
        WHEN accessed_web_pages BETWEEN 2 AND 5 THEN 'Moderate Web User'
        ELSE 'Infrequent Web User'
    END AS web_usage_category
FROM 
    Customer_Analysis ca
WHERE 
    ca.cd_gender = 'M' 
    AND ca.cd_marital_status = 'S'
ORDER BY 
    ca.c_last_name, ca.c_first_name;
