
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_county DESC) AS city_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IN ('NY', 'CA')
),
FilteredAddresses AS (
    SELECT 
        ca_address_sk,
        full_address
    FROM 
        RankedAddresses
    WHERE 
        city_rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        f.full_address
    FROM 
        customer c
    JOIN 
        FilteredAddresses f 
    ON 
        c.c_current_addr_sk = f.ca_address_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_sales_price) AS total_spent
FROM 
    CustomerInfo ci
LEFT JOIN 
    catalog_sales cs 
ON 
    ci.c_customer_sk = cs.cs_bill_customer_sk
GROUP BY 
    ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.full_address
ORDER BY 
    total_spent DESC
LIMIT 10;
