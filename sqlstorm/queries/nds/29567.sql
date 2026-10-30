
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_customer_sk) AS state_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), ranked_customers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state,
        ca_country,
        state_rank
    FROM customer_info
    WHERE state_rank <= 10
), aggregated_info AS (
    SELECT 
        ca_state,
        COUNT(*) AS customer_count,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count,
        COUNT(CASE WHEN cd_marital_status = 'S' THEN 1 END) AS single_count,
        COUNT(CASE WHEN cd_education_status LIKE '%graduate%' THEN 1 END) AS graduate_count
    FROM 
        ranked_customers
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    customer_count,
    female_count,
    single_count,
    graduate_count,
    ROUND((female_count * 100.0) / customer_count, 2) AS female_percentage,
    ROUND((single_count * 100.0) / customer_count, 2) AS single_percentage,
    ROUND((graduate_count * 100.0) / customer_count, 2) AS graduate_percentage
FROM 
    aggregated_info
ORDER BY 
    customer_count DESC;
