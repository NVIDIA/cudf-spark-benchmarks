
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 5
),
ProcessedAddresses AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_customer_id
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
FinalReport AS (
    SELECT 
        tc.full_name,
        tc.cd_gender,
        tc.cd_marital_status,
        pa.full_address,
        pa.ca_city,
        pa.ca_state,
        pa.ca_country
    FROM 
        TopCustomers tc
    JOIN 
        ProcessedAddresses pa ON tc.c_customer_id = pa.c_customer_id
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    ca_city,
    ca_state,
    ca_country
FROM 
    FinalReport
ORDER BY 
    cd_gender, full_name;
