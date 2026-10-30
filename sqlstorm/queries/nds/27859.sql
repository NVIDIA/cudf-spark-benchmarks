
WITH CustomerFullInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count || '-' || cd.cd_dep_employed_count || '-' || cd.cd_dep_college_count AS dependents_info
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedPurchaseEstimates AS (
    SELECT 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS customer_count
    FROM 
        CustomerFullInfo
    GROUP BY 
        gender
),
StateCityInfo AS (
    SELECT 
        ca.ca_state,
        ca.ca_city,
        COUNT(*) AS city_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state, ca.ca_city
)
SELECT 
    cf.full_name,
    cf.ca_city,
    cf.ca_state,
    ap.avg_purchase_estimate,
    sc.city_count
FROM 
    CustomerFullInfo cf
JOIN 
    AggregatedPurchaseEstimates ap ON cf.cd_gender = ap.gender
JOIN 
    StateCityInfo sc ON cf.ca_state = sc.ca_state AND cf.ca_city = sc.ca_city
WHERE 
    ap.customer_count > 10 AND 
    sc.city_count > 5
ORDER BY 
    ap.avg_purchase_estimate DESC, 
    sc.city_count DESC;
