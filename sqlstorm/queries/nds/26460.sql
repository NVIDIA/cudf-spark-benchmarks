
WITH AddressProcessed AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ab.full_address,
        ab.address_length
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressProcessed ab ON c.c_current_addr_sk = ab.ca_address_sk
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(address_length) AS avg_address_length,
    cd_gender,
    cd_marital_status,
    COUNT(*) FILTER (WHERE cd_credit_rating = 'High') AS high_credit_count,
    COUNT(*) FILTER (WHERE cd_credit_rating = 'Low') AS low_credit_count
FROM 
    CustomerDetails
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    cd_gender, cd_marital_status;
