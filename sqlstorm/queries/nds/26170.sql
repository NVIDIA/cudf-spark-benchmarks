
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CountByState AS (
    SELECT 
        ai.ca_state,
        COUNT(DISTINCT ci.c_customer_id) AS customer_count
    FROM 
        AddressInfo AS ai
    JOIN 
        CustomerInfo AS ci ON ai.ca_address_id = ci.c_customer_id
    GROUP BY 
        ai.ca_state
)
SELECT 
    c.ca_state,
    c.customer_count,
    ROW_NUMBER() OVER (ORDER BY c.customer_count DESC) AS rank,
    CONCAT('State: ', c.ca_state, ' - Customer Count: ', c.customer_count) AS summary
FROM 
    CountByState AS c
WHERE 
    c.customer_count > 20
ORDER BY 
    c.customer_count DESC;
