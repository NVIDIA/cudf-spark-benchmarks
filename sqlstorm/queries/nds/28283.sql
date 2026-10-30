
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CA.ca_city,
        CA.ca_state,
        CD.cd_gender,
        CD.cd_marital_status,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_gender = CD.cd_gender) AS gender_count,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_marital_status = CD.cd_marital_status) AS marital_count
    FROM 
        customer c
    JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
),
Ranking AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        gender_count,
        marital_count,
        RANK() OVER (PARTITION BY ca_state ORDER BY gender_count DESC) AS gender_rank,
        RANK() OVER (PARTITION BY ca_city ORDER BY marital_count DESC) AS marital_rank
    FROM 
        CustomerDetails
)
SELECT 
    
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    gender_count,
    marital_count,
    gender_rank,
    marital_rank,
    CASE 
        WHEN gender_rank <= 5 THEN 'Top Gender'
        ELSE 'Other'
    END AS Gender_Status,
    CASE 
        WHEN marital_rank <= 5 THEN 'Top Marital'
        ELSE 'Other'
    END AS Marital_Status
FROM 
    Ranking
WHERE 
    cd_gender IS NOT NULL
ORDER BY 
    ca_state, gender_count DESC;
