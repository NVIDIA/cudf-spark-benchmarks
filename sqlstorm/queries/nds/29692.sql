
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        c.c_email_address,
        d.d_date AS registration_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
),
StringBenchmark AS (
    SELECT 
        a.ca_address_sk,
        c.customer_name,
        LENGTH(a.full_address) AS address_length,
        CHAR_LENGTH(c.customer_name) AS customer_name_length,
        SUBSTRING(c.customer_name, 1, 10) AS customer_name_prefix,
        UPPER(c.customer_name) AS customer_name_uppercase,
        LOWER(c.customer_name) AS customer_name_lowercase,
        POSITION(' ' IN c.customer_name) AS first_space_position,
        COALESCE(NULLIF(c.c_email_address, ''), 'No Email') AS email_status
    FROM 
        AddressParts a
    JOIN 
        CustomerDetails c ON a.ca_address_sk = c.c_customer_sk
)
SELECT 
    address_length,
    customer_name_length,
    COUNT(*) AS record_count,
    AVG(address_length) AS avg_address_length,
    AVG(customer_name_length) AS avg_customer_name_length,
    SUM(CASE WHEN first_space_position > 0 THEN 1 ELSE 0 END) AS names_with_space,
    SUM(CASE WHEN email_status = 'No Email' THEN 1 ELSE 0 END) AS customers_without_email
FROM
    StringBenchmark
GROUP BY 
    address_length, customer_name_length
ORDER BY 
    address_length DESC, customer_name_length DESC;
