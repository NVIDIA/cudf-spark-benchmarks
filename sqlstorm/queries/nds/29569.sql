
WITH filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND ca.ca_city LIKE '%New%'
),
gender_count AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM filtered_customers
    GROUP BY cd_gender
),
demographic_summary AS (
    SELECT 
        fd.*,
        gc.gender_count
    FROM 
        filtered_customers fd
    JOIN gender_count gc ON fd.cd_gender = gc.cd_gender
)
SELECT 
    full_name,
    ca_city,
    cd_gender,
    gender_count,
    CONCAT('Customer: ', full_name, ' from ', ca_city, ' is ', cd_gender, ' and belongs to a group of ', gender_count, ' in the city.') AS customer_summary
FROM 
    demographic_summary
ORDER BY 
    ca_city, full_name;
