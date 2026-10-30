
WITH enriched_customer AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country,
        LENGTH(c.c_email_address) AS email_length,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 499 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 999 THEN 'Medium'
            WHEN cd.cd_purchase_estimate >= 1000 THEN 'High'
            ELSE 'Unknown' 
        END AS purchase_estimate_band
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
customer_summary AS (
    SELECT 
        ec.ca_state, 
        ec.purchase_estimate_band, 
        COUNT(ec.c_customer_sk) AS customer_count, 
        AVG(ec.email_length) AS avg_email_length
    FROM 
        enriched_customer ec
    GROUP BY 
        ec.ca_state, ec.purchase_estimate_band
)
SELECT 
    cs.ca_state, 
    cs.purchase_estimate_band, 
    cs.customer_count, 
    cs.avg_email_length,
    RANK() OVER (PARTITION BY cs.ca_state ORDER BY cs.customer_count DESC) AS rank_within_state
FROM 
    customer_summary cs
ORDER BY 
    cs.ca_state, rank_within_state;
