
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, 
                  COALESCE(ca_suite_number, ''), ca_city, ca_county, 
                  ca_state, ca_zip, ca_country) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper
    FROM 
        customer_address
), 
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        LEAST(cd_dep_count, COALESCE(cd_dep_employed_count, 0) + COALESCE(cd_dep_college_count, 0)) AS total_dependents
    FROM 
        customer_demographics
),
StoreInfo AS (
    SELECT 
        s_store_sk,
        CONCAT(s_store_name, ' located in ', s_city, ', ', s_state) AS store_description
    FROM 
        store
),
CustomerAddressDemographics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.total_dependents,
        s.store_description
    FROM 
        customer c
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        StoreInfo s ON c.c_current_hdemo_sk = s.s_store_sk
)

SELECT 
    customer_name,
    full_address,
    cd_gender,
    cd_marital_status,
    total_dependents,
    store_description
FROM 
    CustomerAddressDemographics
WHERE 
    total_dependents > 0
ORDER BY 
    cd_gender DESC, 
    total_dependents DESC, 
    customer_name ASC
LIMIT 100;
