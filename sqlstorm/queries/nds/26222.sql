
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS Full_Address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_street_name) AS Address_Rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
PopularCities AS (
    SELECT 
        ca_city,
        COUNT(*) AS Address_Count
    FROM 
        customer_address
    GROUP BY 
        ca_city
    HAVING 
        COUNT(*) > 10
)
SELECT 
    addr.ca_address_sk,
    addr.Full_Address,
    city.Address_Count
FROM 
    RankedAddresses addr
JOIN 
    PopularCities city ON addr.Full_Address LIKE '%' || city.ca_city || '%'
WHERE 
    addr.Address_Rank <= 5
ORDER BY 
    city.Address_Count DESC, addr.Full_Address
LIMIT 50;
