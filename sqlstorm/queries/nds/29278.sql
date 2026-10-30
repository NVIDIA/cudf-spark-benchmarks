
WITH ProcessedCustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COALESCE(cd.cd_dep_count, 0) AS dependency_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_dependents,
        COALESCE(cd.cd_dep_college_count, 0) AS college_dependents,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_description,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        UPPER(c.c_email_address) AS email_uppercase
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL 
        AND ca.ca_state IN ('NY', 'CA', 'TX')
),
DemographicStatistics AS (
    SELECT 
        COUNT(*) AS total_customers,
        COUNT(DISTINCT cd_gender) AS unique_genders,
        SUM(dependency_count) AS total_dependencies,
        AVG(college_dependents) AS avg_college_dependents
    FROM 
        ProcessedCustomerData
)
SELECT 
    pcd.c_customer_id,
    pcd.full_name,
    pcd.gender_description,
    d.total_customers,
    d.unique_genders,
    d.total_dependencies,
    d.avg_college_dependents
FROM 
    ProcessedCustomerData AS pcd
CROSS JOIN 
    DemographicStatistics AS d
ORDER BY 
    pcd.full_name ASC;
