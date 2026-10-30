
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        CD.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_last_name) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'CA'
),
AggregatePurchaseEstimates AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.ca_city,
    rc.ca_state,
    rc.cd_gender,
    rc.cd_marital_status,
    ap.total_customers,
    ap.avg_purchase_estimate,
    rc.city_rank
FROM 
    RankedCustomers rc
JOIN 
    AggregatePurchaseEstimates ap ON rc.cd_gender = ap.cd_gender
WHERE 
    rc.city_rank <= 5
ORDER BY 
    rc.ca_city, rc.c_last_name;
