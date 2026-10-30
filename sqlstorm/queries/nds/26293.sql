
WITH AddressCombos AS (
    SELECT 
        ca_city, 
        ca_state, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS addr_count
    FROM customer_address
    GROUP BY ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
),
CustomerMetrics AS (
    SELECT 
        cd_gender,
        COUNT(c.c_customer_sk) AS total_customers,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    ac.full_address,
    cm.cd_gender,
    cm.total_customers,
    cm.married_count,
    cm.single_count,
    cm.avg_purchase_estimate
FROM AddressCombos ac
JOIN CustomerMetrics cm ON cm.total_customers > 0
ORDER BY ac.ca_state, ac.ca_city, cm.cd_gender;
