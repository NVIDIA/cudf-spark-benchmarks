
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) || 
        CASE WHEN ca_suite_number IS NOT NULL THEN ' Suite ' || TRIM(ca_suite_number) ELSE '' END AS full_address
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        TRIM(c.c_first_name) || ' ' || TRIM(c.c_last_name) AS full_name,
        d.d_date AS join_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        a.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM CustomerDetails
    GROUP BY cd_gender
),
LocationStats AS (
    SELECT 
        SUBSTRING(full_address, POSITION(' ' IN full_address) + 1, POSITION(',' IN full_address) - POSITION(' ' IN full_address) - 1) AS city,
        COUNT(*) AS customers_in_city,
        AVG(cd_purchase_estimate) AS avg_estimate_per_city
    FROM CustomerDetails
    GROUP BY city
)
SELECT 
    g.cd_gender,
    g.total_customers,
    g.avg_purchase_estimate,
    l.city,
    l.customers_in_city,
    l.avg_estimate_per_city
FROM GenderStats g
JOIN LocationStats l ON l.customers_in_city = (SELECT MAX(customers_in_city) FROM LocationStats)
ORDER BY g.cd_gender, l.city;
