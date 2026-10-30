
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        full_name, 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        c_customer_sk
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.cd_purchase_estimate,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    CONCAT('Customer ', tc.full_name, ' from ', ca.ca_city, ', ', ca.ca_state, ' has a purchase estimate of ', tc.cd_purchase_estimate, '.') AS customer_info
FROM 
    TopCustomers tc
    JOIN CustomerAddresses ca ON tc.c_customer_sk = ca.c_customer_sk
ORDER BY 
    tc.cd_purchase_estimate DESC;
