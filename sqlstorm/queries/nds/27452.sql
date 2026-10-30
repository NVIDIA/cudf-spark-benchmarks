
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        RankedCustomers
    WHERE 
        rnk <= 5
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name || ' ' || ca.ca_street_type AS full_street_name,
        ca.ca_city,
        ca.ca_state,
        c.c_customer_id
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.cd_purchase_estimate,
    ca.full_street_name,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    CustomerAddresses ca ON tc.c_customer_id = ca.c_customer_id
ORDER BY 
    tc.cd_purchase_estimate DESC;
