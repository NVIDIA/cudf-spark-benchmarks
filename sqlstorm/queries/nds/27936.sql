
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        rc.c_customer_id,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        RankedCustomers rc
    JOIN 
        customer_address ca ON rc.c_customer_id = SUBSTRING(ca.ca_address_id, 1, 16)
    WHERE 
        rc.rank <= 5
),
GenderStats AS (
    SELECT
        cd.cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    gs.total_customers,
    gs.average_purchase_estimate
FROM 
    CustomerAddresses ca
JOIN 
    GenderStats gs ON ca.c_customer_id IN (SELECT c_customer_id FROM RankedCustomers)
ORDER BY 
    ca.ca_city, ca.ca_state;
