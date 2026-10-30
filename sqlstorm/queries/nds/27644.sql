
WITH CombinedNames AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), CityCount AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS customer_count
    FROM customer_address
    GROUP BY ca_city, ca_state
), GenderCount AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM customer_demographics
    GROUP BY cd_gender
), EducationStats AS (
    SELECT 
        cd_education_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_education_status
)
SELECT 
    cn.full_name,
    cn.cd_gender,
    cn.ca_city,
    cn.ca_state,
    cc.customer_count,
    gc.gender_count,
    es.avg_purchase_estimate
FROM CombinedNames cn
JOIN CityCount cc ON cn.ca_city = cc.ca_city AND cn.ca_state = cc.ca_state
JOIN GenderCount gc ON cn.cd_gender = gc.cd_gender
JOIN EducationStats es ON cn.cd_education_status = es.cd_education_status
WHERE cn.cd_marital_status = 'M'
ORDER BY cn.ca_state, cn.ca_city, cn.full_name;
