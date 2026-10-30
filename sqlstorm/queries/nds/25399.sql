
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        trim(concat(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
WarehouseParts AS (
    SELECT 
        w_warehouse_sk, 
        trim(concat(w_street_number, ' ', w_street_name, ' ', w_street_type)) AS full_address,
        w_city,
        w_state,
        w_zip,
        w_country
    FROM 
        warehouse
),
CombinedAddresses AS (
    SELECT 
        'Customer' AS address_type,
        full_address,
        ca_city AS city,
        ca_state AS state,
        ca_zip AS zip,
        ca_country AS country
    FROM 
        AddressParts
    UNION ALL
    SELECT 
        'Warehouse' AS address_type,
        full_address,
        w_city AS city,
        w_state AS state,
        w_zip AS zip,
        w_country AS country
    FROM 
        WarehouseParts
),
DistinctAddresses AS (
    SELECT DISTINCT 
        full_address, 
        city, 
        state, 
        zip, 
        country 
    FROM 
        CombinedAddresses
)
SELECT 
    city, 
    state, 
    COUNT(DISTINCT full_address) AS distinct_address_count
FROM 
    DistinctAddresses
GROUP BY 
    city, 
    state
ORDER BY 
    state, 
    distinct_address_count DESC;
