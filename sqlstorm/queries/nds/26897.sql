
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
formatted_customers AS (
    SELECT 
        c_customer_sk,
        UPPER(CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name))) AS full_name,
        c_email_address,
        cd_gender,
        cd_marital_status
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
customer_details AS (
    SELECT 
        pc.ca_address_sk,
        pc.full_address,
        fc.full_name,
        fc.c_email_address,
        fc.cd_gender,
        fc.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY pc.ca_state ORDER BY pc.ca_address_sk) AS address_rank
    FROM processed_addresses pc
    JOIN formatted_customers fc ON pc.ca_address_sk = fc.c_customer_sk
)
SELECT 
    full_address,
    full_name,
    c_email_address,
    cd_gender,
    cd_marital_status,
    address_rank
FROM customer_details
WHERE address_rank <= 10
ORDER BY cd_gender, address_rank;
