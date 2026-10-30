
WITH ProcessedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        TRIM(CONCAT_WS(' ', 
            ca.ca_street_number, 
            ca.ca_street_name, 
            ca.ca_street_type, 
            CASE WHEN ca.ca_suite_number IS NULL OR ca.ca_suite_number = '' THEN '' ELSE CONCAT('Apt ', TRIM(ca.ca_suite_number)) END,
            ca.ca_city, 
            ca.ca_state, 
            ca.ca_zip, 
            ca.ca_country
        )) AS full_address
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnCounts AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    pa.full_address,
    COALESCE(rc.total_returns, 0) AS total_returns,
    COALESCE(rc.total_return_value, 0.00) AS total_return_value
FROM 
    CustomerInfo ci
JOIN 
    ProcessedAddresses pa ON ci.c_customer_sk = pa.ca_address_sk
LEFT JOIN 
    ReturnCounts rc ON ci.c_customer_sk = rc.sr_customer_sk
WHERE 
    ci.cd_gender = 'F'
    AND COALESCE(rc.total_returns, 0) > 5
ORDER BY 
    total_return_value DESC
LIMIT 100;
