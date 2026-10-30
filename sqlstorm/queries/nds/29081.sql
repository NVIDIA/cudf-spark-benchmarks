
WITH Address_Analysis AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_street_type,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'TX', 'NY')
), Customer_Demo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        SUBSTRING(cd_education_status FROM 1 FOR 10) AS short_education,
        FLOOR(cd_purchase_estimate/1000) * 1000 AS purchase_band
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
), Aggregated_Data AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        d.short_education,
        COUNT(*) AS customer_count,
        AVG(a.street_name_length) AS avg_street_name_length,
        AVG(a.city_length) AS avg_city_length,
        AVG(a.state_length) AS avg_state_length,
        SUM(d.purchase_band) AS total_purchase_band
    FROM 
        Address_Analysis a
    JOIN 
        Customer_Demo d ON a.ca_address_sk = d.cd_demo_sk
    GROUP BY 
        a.ca_city, a.ca_state, d.short_education
)

SELECT 
    ca_city,
    ca_state,
    short_education,
    customer_count,
    avg_street_name_length,
    avg_city_length,
    avg_state_length,
    total_purchase_band
FROM 
    Aggregated_Data
WHERE 
    customer_count > 5
ORDER BY 
    total_purchase_band DESC, 
    customer_count DESC;
