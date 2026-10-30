
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip
    FROM customer_address
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate,
        CONCAT(cd_gender, '_', cd_marital_status) AS demo_key
    FROM customer_demographics
), 
CombinedData AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.full_address,
        cd.demo_key,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    full_name, 
    full_address, 
    demo_key, 
    COUNT(*) AS address_count,
    SUM(cd_purchase_estimate) AS total_purchase_estimate
FROM CombinedData
GROUP BY full_name, full_address, demo_key
HAVING COUNT(*) > 1
ORDER BY total_purchase_estimate DESC;
