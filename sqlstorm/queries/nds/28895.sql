
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),

DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        CONCAT('Gender: ', cd_gender, ', Marital Status: ', cd_marital_status, ', Education: ', cd_education_status) AS demographic_info,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),

EnhancedCustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        d.demographic_info,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
)

SELECT 
    e.full_name,
    e.full_address,
    e.demographic_info,
    e.cd_purchase_estimate,
    e.cd_credit_rating
FROM 
    EnhancedCustomerData e
WHERE 
    e.cd_purchase_estimate > 500
ORDER BY 
    e.cd_purchase_estimate DESC;
