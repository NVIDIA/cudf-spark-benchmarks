
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), RankedCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY cd_purchase_estimate DESC) AS rank
    FROM CustomerData
), FilteredCustomers AS (
    SELECT
        *,
        CASE 
            WHEN cd_purchase_estimate >= 5000 THEN 'High Value'
            WHEN cd_purchase_estimate BETWEEN 2000 AND 4999 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM RankedCustomers
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    customer_value_segment,
    ca_city,
    ca_state,
    ca_country
FROM FilteredCustomers
WHERE rank <= 10
ORDER BY ca_state, cd_purchase_estimate DESC;
