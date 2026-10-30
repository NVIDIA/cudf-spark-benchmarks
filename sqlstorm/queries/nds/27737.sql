
WITH AddressDetails AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
    GROUP BY ca.ca_city, ca.ca_state, ca.ca_country
),
ProcessedData AS (
    SELECT 
        ca_address.ca_city,
        ca_address.ca_state,
        ca_address.ca_country,
        CONCAT(ca_address.ca_city, ', ', ca_address.ca_state, ', ', ca_address.ca_country) AS full_address,
        ca_address.customer_count,
        ca_address.average_purchase_estimate,
        LENGTH(CONCAT(ca_address.ca_city, ', ', ca_address.ca_state, ', ', ca_address.ca_country)) AS address_length,
        UPPER(CONCAT(ca_address.ca_city, ', ', ca_address.ca_state, ', ', ca_address.ca_country)) AS upper_address
    FROM AddressDetails ca_address
)
SELECT 
    pd.full_address,
    pd.customer_count,
    pd.average_purchase_estimate,
    pd.address_length,
    pd.upper_address
FROM ProcessedData pd
WHERE pd.customer_count > 0
ORDER BY pd.customer_count DESC, pd.address_length ASC;
