
WITH processed_address AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS city_uppercase,
        REPLACE(ca_zip, '-', '') AS clean_zip
    FROM 
        customer_address
),
processed_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS purchase_value_category,
        INITCAP(cd_education_status) AS education_status_updated
    FROM 
        customer_demographics
),
custom_report AS (
    SELECT 
        pa.ca_address_sk,
        pd.cd_demo_sk,
        pa.full_address,
        pa.street_name_length,
        pa.city_uppercase,
        pd.purchase_value_category,
        pd.education_status_updated
    FROM 
        processed_address pa
    JOIN 
        processed_demographics pd ON pd.cd_demo_sk = pa.ca_address_sk % 1000  
)
SELECT 
    cr.full_address,
    cr.city_uppercase,
    cr.purchase_value_category,
    COUNT(*) AS total_customers,
    AVG(cr.street_name_length) AS avg_street_name_length
FROM 
    custom_report cr
GROUP BY 
    cr.full_address, cr.city_uppercase, cr.purchase_value_category, cr.street_name_length
HAVING 
    COUNT(*) > 1
ORDER BY 
    avg_street_name_length DESC;
