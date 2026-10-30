
WITH CustomerWithAddresses AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        c.c_email_address,
        LENGTH(ca.ca_city) AS city_length,
        LENGTH(ca.ca_state) AS state_length,
        LENGTH(ca.ca_zip) AS zip_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
CustomerDemographicStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_count) AS total_dependents,
        SUM(cd.cd_dep_employed_count) AS total_employed_dep,
        SUM(cd.cd_dep_college_count) AS total_college_dep
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    a.c_customer_id,
    a.full_name,
    a.full_address,
    a.c_email_address,
    a.city_length,
    a.state_length,
    a.zip_length,
    d.cd_gender,
    d.customer_count,
    d.avg_purchase_estimate,
    d.total_dependents,
    d.total_employed_dep,
    d.total_college_dep
FROM 
    CustomerWithAddresses a
JOIN 
    CustomerDemographicStats d ON a.full_name LIKE CONCAT('%', d.cd_gender, '%')
WHERE 
    a.city_length > 5
ORDER BY 
    a.c_last_name, a.c_first_name;
