
WITH ranked_addresses AS (
    SELECT 
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) as rn
    FROM 
        customer_address 
    WHERE 
        UPPER(ca_city) LIKE 'A%' AND 
        LENGTH(ca_street_name) > 5
), 
customer_gender_count AS (
    SELECT 
        cd_gender,
        COUNT(*) as gender_count
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender
), 
customer_city_stats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS unique_customers,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_city
)
SELECT 
    r.ca_address_id,
    r.ca_street_name,
    r.ca_city,
    r.ca_state,
    g.cd_gender,
    g.gender_count,
    c.unique_customers,
    c.total_purchase_estimate
FROM 
    ranked_addresses r
JOIN 
    customer_gender_count g ON g.gender_count > 1
JOIN 
    customer_city_stats c ON r.ca_city = c.ca_city
WHERE 
    r.rn <= 5
ORDER BY 
    r.ca_state, r.ca_city, LENGTH(r.ca_street_name) DESC;
