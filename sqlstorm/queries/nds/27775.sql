
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressAggregation AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT r.c_customer_id) AS customer_count,
        AVG(r.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        RankedCustomers r ON c.c_customer_id = r.c_customer_id
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    aa.ca_city,
    aa.ca_state,
    aa.customer_count,
    aa.avg_purchase_estimate,
    (SELECT COUNT(*) FROM customer) AS total_customers,
    (SELECT COUNT(*) FROM customer_demographics) AS total_demographics
FROM 
    AddressAggregation aa
WHERE 
    aa.customer_count > (SELECT AVG(customer_count) FROM AddressAggregation)
ORDER BY 
    aa.avg_purchase_estimate DESC
LIMIT 10;
