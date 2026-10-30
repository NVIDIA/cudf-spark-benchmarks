
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name) AS address_without_type
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ac.full_address,
        ac.ca_city,
        ac.ca_state,
        ac.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.full_address,
        c.ca_city,
        c.ca_state,
        c.ca_zip
    FROM 
        CustomerDetails c
    WHERE 
        c.cd_gender = 'F' AND 
        c.cd_marital_status = 'M' AND 
        c.ca_city LIKE '%York%' 
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fc.full_address,
    fc.ca_city,
    CONCAT(fc.ca_state, ' ', fc.ca_zip) AS state_zip,
    COUNT(ws.ws_order_number) AS total_orders
FROM 
    FilteredCustomers fc
LEFT JOIN 
    web_sales ws ON fc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    fc.c_first_name, 
    fc.c_last_name, 
    fc.full_address, 
    fc.ca_city, 
    fc.ca_state, 
    fc.ca_zip
ORDER BY 
    total_orders DESC, 
    fc.c_last_name, 
    fc.c_first_name
LIMIT 100;
