
WITH processed_customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
aggregated_info AS (
    SELECT 
        ca_state,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        processed_customer_info
    GROUP BY 
        ca_state
),
ranked_info AS (
    SELECT 
        ca_state,
        customer_count,
        avg_purchase_estimate,
        RANK() OVER (ORDER BY avg_purchase_estimate DESC) AS rank_sales
    FROM 
        aggregated_info
)
SELECT 
    ca_state,
    customer_count,
    avg_purchase_estimate,
    rank_sales
FROM 
    ranked_info
WHERE 
    rank_sales <= 5
ORDER BY 
    rank_sales;
