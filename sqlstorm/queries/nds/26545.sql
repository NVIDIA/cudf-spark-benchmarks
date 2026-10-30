
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
city_rankings AS (
    SELECT 
        ca_city,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_info
    WHERE 
        rank <= 10
    GROUP BY 
        ca_city
),
city_statistics AS (
    SELECT 
        ca_city,
        customer_count,
        avg_purchase_estimate,
        RANK() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM 
        city_rankings
)
SELECT 
    cs.ca_city,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.city_rank
FROM 
    city_statistics cs
JOIN 
    (SELECT DISTINCT ca_state FROM customer_address) s ON TRUE
WHERE 
    cs.customer_count > 0
ORDER BY 
    cs.city_rank;
