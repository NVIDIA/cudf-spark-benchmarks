
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CityCounts AS (
    SELECT 
        ci.ca_city,
        COUNT(*) AS total_customers
    FROM CustomerInfo ci
    GROUP BY ci.ca_city
),
PersonalStats AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        cc.total_customers,
        CASE 
            WHEN ci.cd_purchase_estimate > 50000 THEN 'High Value'
            WHEN ci.cd_purchase_estimate BETWEEN 20000 AND 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM CustomerInfo ci
    JOIN CityCounts cc ON ci.ca_city = cc.ca_city
)
SELECT 
    ps.full_name,
    ps.ca_city,
    ps.ca_state,
    ps.cd_gender,
    ps.cd_marital_status,
    ps.cd_education_status,
    ps.cd_purchase_estimate,
    ps.total_customers,
    ps.customer_value_category
FROM PersonalStats ps
ORDER BY ps.customer_value_category DESC, ps.total_customers DESC;
