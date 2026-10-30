
WITH RankedAddresses AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY COUNT(*) DESC) AS city_rank
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
ExtendedAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_street_type,
        ca.ca_suite_number,
        ca.ca_city,
        ca.ca_state,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        rd.address_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        RankedAddresses rd ON rd.ca_city = ca.ca_city AND rd.ca_state = ca.ca_state
    WHERE 
        rd.city_rank <= 3  
)
SELECT 
    CONCAT(ea.ca_street_number, ' ', ea.ca_street_name, ' ', ea.ca_street_type) AS full_address,
    ea.ca_city,
    ea.ca_state,
    ea.c_first_name,
    ea.c_last_name,
    ea.c_email_address,
    ea.address_count
FROM 
    ExtendedAddresses ea
ORDER BY 
    ea.ca_city, ea.ca_state, full_address;
