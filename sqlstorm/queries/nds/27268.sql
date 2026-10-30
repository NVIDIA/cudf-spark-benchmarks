
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT
        ca_address_sk,
        full_address,
        address_length,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        AddressParts
    WHERE 
        address_length > 20 AND ca_city IS NOT NULL AND ca_state = 'CA'
),
DemographicData AS (
    SELECT 
        ca.ca_address_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        FilteredAddresses AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    dd.ca_address_sk,
    dd.cd_gender,
    dd.cd_marital_status,
    CONCAT('Purchase Estimate: $', dd.cd_purchase_estimate) AS formatted_estimate,
    LENGTH(dd.cd_marital_status) AS marital_status_length
FROM 
    DemographicData AS dd
WHERE 
    dd.cd_purchase_estimate > 1000
ORDER BY 
    dd.cd_purchase_estimate DESC
LIMIT 100;
