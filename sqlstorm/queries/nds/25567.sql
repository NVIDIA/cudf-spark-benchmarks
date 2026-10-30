
WITH enriched_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city AS address_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT('$', cd.cd_credit_rating) AS formatted_credit_rating,
        (SELECT COUNT(*) FROM customer_demographics) AS total_customers
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
distinct_addresses AS (
    SELECT DISTINCT 
        address_city
    FROM 
        enriched_customers
),
customer_benchmarks AS (
    SELECT
        e.full_name,
        e.address_city,
        e.cd_gender,
        e.cd_marital_status,
        e.cd_education_status,
        e.cd_purchase_estimate,
        e.formatted_credit_rating,
        d.address_city AS distinct_address,
        e.total_customers
    FROM 
        enriched_customers e
    JOIN 
        distinct_addresses d ON e.address_city = d.address_city
)
SELECT 
    cb.full_name,
    cb.address_city,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.cd_education_status,
    cb.cd_purchase_estimate,
    cb.formatted_credit_rating,
    COUNT(cb.distinct_address) OVER (PARTITION BY cb.address_city) AS address_count,
    MAX(cb.total_customers) OVER () AS customer_base_size
FROM 
    customer_benchmarks cb
WHERE 
    cb.cd_purchase_estimate > (SELECT AVG(cd.cd_purchase_estimate) FROM customer_demographics cd)
ORDER BY 
    cb.cd_purchase_estimate DESC;
