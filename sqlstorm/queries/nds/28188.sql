
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopConsumers AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        RankedCustomers
    WHERE 
        rn <= 5
),
ConsumerStats AS (
    SELECT 
        ca_state,
        cd_gender,
        COUNT(*) AS total_consumers,
        COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS married_count,
        COUNT(CASE WHEN cd_marital_status = 'S' THEN 1 END) AS single_count,
        COUNT(CASE WHEN cd_education_status LIKE '%Bachelor%' THEN 1 END) AS bachelor_count
    FROM 
        TopConsumers
    GROUP BY 
        ca_state, cd_gender
)
SELECT 
    ca_state,
    cd_gender,
    total_consumers,
    married_count,
    single_count,
    bachelor_count,
    ROUND((married_count * 100.0) / NULLIF(total_consumers, 0), 2) AS married_percentage,
    ROUND((single_count * 100.0) / NULLIF(total_consumers, 0), 2) AS single_percentage,
    ROUND((bachelor_count * 100.0) / NULLIF(total_consumers, 0), 2) AS bachelor_percentage
FROM 
    ConsumerStats
ORDER BY 
    ca_state, cd_gender;
