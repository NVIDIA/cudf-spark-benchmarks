
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_login_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d ON c.c_last_review_date_sk = d.d_date_sk
),
AggregatedData AS (
    SELECT 
        cd.full_name,
        COUNT(DISTINCT cd.last_login_date) AS login_count,
        COUNT(DISTINCT cd.cd_gender) AS distinct_genders,
        COUNT(DISTINCT cd.cd_marital_status) AS distinct_marital_status,
        COUNT(DISTINCT cd.cd_education_status) AS distinct_education_status,
        ARRAY_AGG(DISTINCT cd.full_address) AS address_list,
        ARRAY_AGG(DISTINCT cd.ca_city) AS city_list,
        ARRAY_AGG(DISTINCT cd.ca_state) AS state_list
    FROM 
        CustomerData cd
    GROUP BY 
        cd.full_name
)
SELECT 
    ad.full_name,
    ad.login_count,
    ad.distinct_genders,
    ad.distinct_marital_status,
    ad.distinct_education_status,
    ad.address_list,
    ad.city_list,
    ad.state_list
FROM 
    AggregatedData ad
WHERE 
    ad.login_count > 1
ORDER BY 
    ad.full_name;
