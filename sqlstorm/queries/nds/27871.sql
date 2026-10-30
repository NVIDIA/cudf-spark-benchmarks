
WITH CustomerData AS (
    SELECT 
        CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        ca.ca_country,
        COALESCE(cd.cd_dep_college_count, 0) AS college_count,
        COALESCE(cd.cd_dep_count, 0) AS total_dependent_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregatedData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS total_customers,
        AVG(cd.college_count) AS avg_college_count,
        AVG(cd.total_dependent_count) AS avg_dep_count
    FROM 
        CustomerData cd
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    ad.cd_gender,
    ad.cd_marital_status,
    ad.total_customers,
    ad.avg_college_count,
    ad.avg_dep_count,
    CASE 
        WHEN ad.avg_college_count > 2 THEN 'High College Count'
        WHEN ad.avg_college_count BETWEEN 1 AND 2 THEN 'Moderate College Count'
        ELSE 'Low College Count'
    END AS college_count_category,
    CASE 
        WHEN ad.total_customers > 100 THEN 'High Participation'
        WHEN ad.total_customers BETWEEN 50 AND 100 THEN 'Moderate Participation'
        ELSE 'Low Participation'
    END AS customer_participation
FROM 
    AggregatedData ad
ORDER BY 
    ad.cd_gender, 
    ad.cd_marital_status;
