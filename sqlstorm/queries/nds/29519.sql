
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS address_length
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
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        ac.full_address,
        ac.address_length
    FROM 
        customer c 
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
),
BenchmarkResults AS (
    SELECT 
        CONCAT(full_name, ' (', cd_gender, ', ', cd_marital_status, ') located at ', full_address) AS customer_description,
        name_length,
        address_length,
        (name_length + address_length) AS total_length
    FROM 
        CustomerDetails
)
SELECT 
    customer_description,
    name_length,
    address_length,
    total_length
FROM 
    BenchmarkResults
ORDER BY 
    total_length DESC
LIMIT 10;
