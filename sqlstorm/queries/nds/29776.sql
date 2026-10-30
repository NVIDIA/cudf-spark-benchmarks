
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank_by_age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
FilteredCustomers AS (
    SELECT 
        rc.full_name,
        rc.full_address,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank_by_age <= 5
)
SELECT 
    fc.full_name,
    fc.full_address,
    fc.cd_gender,
    fc.cd_education_status,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_orders
FROM 
    FilteredCustomers fc
JOIN 
    customer c ON fc.full_name = CONCAT(c.c_first_name, ' ', c.c_last_name)
ORDER BY 
    fc.cd_gender, 
    fc.cd_education_status;
