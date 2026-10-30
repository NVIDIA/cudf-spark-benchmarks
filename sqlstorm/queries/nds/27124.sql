
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_street_name) AS lower_street_name,
        TRIM(ca_street_name) AS trimmed_street_name,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) AS rank
    FROM 
        customer_address
), FilteredAddresses AS (
    SELECT 
        ra.ca_address_sk,
        ra.ca_city,
        ra.ca_state,
        ra.street_name_length,
        ra.upper_street_name,
        ra.lower_street_name,
        ra.trimmed_street_name
    FROM 
        RankedAddresses ra
    WHERE 
        ra.rank <= 5
)
SELECT 
    fa.ca_address_sk,
    fa.ca_city,
    fa.ca_state,
    fa.street_name_length,
    fa.upper_street_name,
    fa.lower_street_name,
    fa.trimmed_street_name,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    FilteredAddresses fa
JOIN 
    customer c ON c.c_current_addr_sk = fa.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    fa.ca_state = 'CA'
ORDER BY 
    fa.street_name_length DESC, fa.ca_city ASC;
