
WITH processed_customers AS (
    SELECT 
        DISTINCT 
        CASE 
            WHEN cd_gender = 'M' THEN CONCAT('Mr. ', c_first_name)
            WHEN cd_gender = 'F' THEN CONCAT('Ms. ', c_first_name)
            ELSE CONCAT('Customer ', c_customer_id)
        END AS customer_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        cd_purchase_estimate,
        CONCAT(c_birth_month, '/', c_birth_day, '/', c_birth_year) AS birth_date_formatted
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd_purchase_estimate > 1000 AND cd_gender IS NOT NULL
),
aggregated_info AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        processed_customers
)
SELECT 
    ci.customer_name, 
    ci.full_address, 
    ci.cd_purchase_estimate AS purchase_estimate,
    ai.total_customers,
    ai.avg_purchase_estimate
FROM 
    processed_customers ci,
    aggregated_info ai
ORDER BY 
    ci.cd_purchase_estimate DESC
LIMIT 10;
