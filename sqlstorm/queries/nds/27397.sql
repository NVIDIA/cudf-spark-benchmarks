
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type || 
        COALESCE(' ' || ca.ca_suite_number, '') || 
        ', ' || ca.ca_city || ', ' || ca.ca_state || ' ' || ca.ca_zip AS full_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FullReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.cd_education_status,
        ca.full_address
    FROM 
        TopCustomers tc
    JOIN 
        CustomerAddresses ca ON tc.c_customer_sk = ca.c_customer_sk
)
SELECT 
    * 
FROM 
    FullReport
ORDER BY 
    cd_gender, c_last_name;
