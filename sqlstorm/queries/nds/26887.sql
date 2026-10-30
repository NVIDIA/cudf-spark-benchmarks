
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(c.c_email_address, 1, 3) AS email_prefix,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS full_name_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND LENGTH(c.c_email_address) > 5
),
DemographicsSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(full_name_length) AS avg_full_name_length
    FROM 
        CustomerData
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
CityStateSummary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS customer_count,
        ARRAY_AGG(full_name) AS customer_names
    FROM 
        CustomerData
    GROUP BY 
        ca_city, 
        ca_state
)

SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count AS total_customers,
    ds.avg_full_name_length,
    css.ca_city,
    css.ca_state,
    css.customer_count AS city_state_customer_count,
    css.customer_names
FROM 
    DemographicsSummary ds
JOIN 
    CityStateSummary css ON ds.customer_count > 5
ORDER BY 
    ds.cd_gender, 
    ds.cd_marital_status, 
    css.ca_city;
