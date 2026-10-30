
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        REPLACE(CONCAT_WS(', ', ca.ca_city, ca.ca_state, ca.ca_zip), ' ,', '') AS address,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    rank.full_name, 
    rank.cd_gender, 
    rank.cd_marital_status, 
    rank.cd_education_status, 
    rank.address
FROM 
    ranked_customers rank
WHERE 
    rank.rn <= 10
ORDER BY 
    rank.cd_gender, 
    rank.cd_purchase_estimate DESC;
