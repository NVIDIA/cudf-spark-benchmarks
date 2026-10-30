
WITH AddressAnalysis AS (
    SELECT
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(CONCAT(ca_street_number, ca_street_name, ca_street_type)) AS address_length,
        (SELECT COUNT(*)
         FROM store
         WHERE CONCAT(s_street_number, ' ', s_street_name, ' ', s_street_type) = CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)
         AND s_city = ca_city) AS store_count
    FROM customer_address
    WHERE ca_country = 'USA'
    ORDER BY ca_city, address_length DESC
),
GenderAnalysis AS (
    SELECT
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN ca_state = 'CA' THEN 1 ELSE 0 END) AS ca_customers
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY cd_gender
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    g.cd_gender,
    g.customer_count,
    g.avg_purchase_estimate,
    g.ca_customers,
    a.store_count
FROM AddressAnalysis a
JOIN GenderAnalysis g ON a.store_count > 0
ORDER BY a.ca_city, g.cd_gender;
