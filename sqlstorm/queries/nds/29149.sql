
WITH processed_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        LENGTH(c.c_email_address) AS email_length,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_customers,
        AVG(email_length) AS avg_email_length
    FROM 
        processed_customers
    GROUP BY 
        ca_state
)
SELECT 
    PAS.full_name,
    PAS.ca_city,
    PAS.ca_state,
    PAS.cd_gender,
    PAS.customer_value_category,
    ASUM.total_customers,
    ASUM.avg_email_length
FROM 
    processed_customers PAS
JOIN 
    address_summary ASUM ON PAS.ca_state = ASUM.ca_state
ORDER BY 
    ASUM.total_customers DESC, 
    PAS.full_name;
