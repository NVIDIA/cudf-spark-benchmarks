
WITH ranked_addresses AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_street_number, 
        ca_street_name, 
        ca_city, 
        ca_state, 
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) AS rank_length,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rank_city
    FROM 
        customer_address
),
filtered_addresses AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_street_number, 
        ca_street_name, 
        ca_city, 
        ca_state
    FROM 
        ranked_addresses
    WHERE 
        rank_length = 1 AND 
        rank_city = 1
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        filtered_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(cd.cd_dep_count) AS avg_dependent_count
    FROM 
        customer_info ci
    JOIN 
        customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.avg_dependent_count,
    (SELECT COUNT(*) FROM customer) AS total_customers
FROM 
    demographic_summary ds
ORDER BY 
    ds.customer_count DESC;
