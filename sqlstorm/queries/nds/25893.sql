
WITH CustomerAddressData AS (
    SELECT 
        CA.ca_address_sk,
        CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type) AS full_address,
        CA.ca_city,
        CA.ca_state,
        CA.ca_zip
    FROM customer_address CA
), 
CustomerDemographics AS (
    SELECT 
        CD.cd_demo_sk,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status,
        CD.cd_purchase_estimate
    FROM customer_demographics CD
),
CustomerData AS (
    SELECT 
        C.c_customer_sk,
        CONCAT(C.c_first_name, ' ', C.c_last_name) AS full_name,
        C.c_email_address,
        CA.full_address,
        CA.ca_city,
        CA.ca_state,
        CA.ca_zip,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status,
        CD.cd_purchase_estimate
    FROM customer C
    JOIN CustomerAddressData CA ON C.c_current_addr_sk = CA.ca_address_sk
    JOIN CustomerDemographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
)
SELECT 
    COUNT(*) AS total_customers,
    COUNT(DISTINCT full_address) AS unique_addresses,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM CustomerData
GROUP BY 
    cd_gender, 
    cd_marital_status, 
    cd_education_status
ORDER BY 
    total_customers DESC;
