
WITH AddressSegments AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressSegments ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
AggregatedData AS (
    SELECT 
        gender,
        count(*) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimate
    FROM 
        CustomerDetails
    GROUP BY 
        gender
)
SELECT 
    gender,
    customer_count,
    total_estimate,
    CASE 
        WHEN total_estimate > 50000 THEN 'High Value'
        WHEN total_estimate BETWEEN 20000 AND 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment
FROM 
    AggregatedData
ORDER BY 
    customer_count DESC;
