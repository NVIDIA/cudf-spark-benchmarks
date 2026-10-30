
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedData AS (
    SELECT 
        ca_state,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
    FROM 
        CustomerData
    GROUP BY 
        ca_state
),
RankedStates AS (
    SELECT 
        ca_state,
        customer_count,
        avg_purchase_estimate,
        male_count,
        female_count,
        married_count,
        single_count,
        RANK() OVER (ORDER BY customer_count DESC) AS state_rank
    FROM 
        AggregatedData
)
SELECT 
    ca_state,
    customer_count,
    avg_purchase_estimate,
    male_count,
    female_count,
    married_count,
    single_count,
    state_rank,
    CONCAT('State: ', ca_state, ' | Customers: ', customer_count, ' | Avg Purchase: $', ROUND(avg_purchase_estimate, 2)) AS summary_info
FROM 
    RankedStates
WHERE 
    state_rank <= 10
ORDER BY 
    state_rank;
