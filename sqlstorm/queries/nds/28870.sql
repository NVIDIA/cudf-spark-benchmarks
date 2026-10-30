
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city, ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate
    FROM 
        CustomerInfo ci
    WHERE 
        ci.purchase_rank <= 5
)
SELECT 
    ca.ca_state,
    COUNT(*) AS num_top_customers,
    AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    TopCustomers ci
JOIN 
    customer_address ca ON ci.ca_city = ca.ca_city AND ci.ca_state = ca.ca_state
GROUP BY 
    ca.ca_state
ORDER BY 
    num_top_customers DESC;
