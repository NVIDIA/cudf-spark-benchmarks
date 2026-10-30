
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', ca_city, ' ', ca_state, ' ', ca_zip)) AS address_length
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        REPLACE(cd_credit_rating, ' ', '') AS clean_credit_rating
    FROM 
        customer_demographics
),
CombinedInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        a.address_length,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.clean_credit_rating
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    CONCAT(customer_name, ' | Address: ', full_address, ' | Gender: ', cd_gender, ' | Marital Status: ', cd_marital_status) AS customer_detail,
    address_length,
    cd_purchase_estimate
FROM 
    CombinedInfo
WHERE 
    address_length > 50 AND
    cd_purchase_estimate > 1000
ORDER BY 
    cd_purchase_estimate DESC
LIMIT 10;
