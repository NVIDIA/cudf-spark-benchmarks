
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip,
        addr.address_length
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN address_parts addr ON c.c_current_addr_sk = addr.ca_address_sk
),
address_stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_customers,
        AVG(address_length) AS avg_address_length
    FROM address_parts
    GROUP BY ca_state
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ci.address_length,
    as_stats.total_customers,
    as_stats.avg_address_length
FROM customer_info ci
JOIN address_stats as_stats ON ci.ca_state = as_stats.ca_state
WHERE ci.cd_purchase_estimate > 5000
ORDER BY as_stats.total_customers DESC, ci.customer_name;
