
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS FullName,
    c.ca_city,
    c.ca_state,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate
FROM 
    RankedCustomers c
WHERE 
    c.PurchaseRank <= 5
ORDER BY 
    c.ca_state, c.cd_purchase_estimate DESC;
