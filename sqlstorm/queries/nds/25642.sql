
WITH full_address AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS complete_address
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_gender_summary AS (
    SELECT 
        fa.complete_address,
        ci.cd_gender,
        COUNT(*) AS total_customers
    FROM 
        full_address fa
    JOIN 
        customer_info ci ON ci.c_customer_sk = fa.ca_address_sk
    GROUP BY 
        fa.complete_address, ci.cd_gender
)
SELECT 
    complete_address,
    SUM(CASE WHEN cd_gender = 'F' THEN total_customers ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN total_customers ELSE 0 END) AS male_customers
FROM 
    address_gender_summary
GROUP BY 
    complete_address
ORDER BY 
    complete_address;
