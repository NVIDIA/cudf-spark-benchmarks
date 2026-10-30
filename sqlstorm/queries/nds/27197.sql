
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        REPLACE(REPLACE(ca_street_name, 'Street', ''), 'St.', '') AS simplified_street_name,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(UPPER(LEFT(ca_city, 1)), LOWER(SUBSTRING(ca_city FROM 2))) AS formatted_city,
        CONCAT(UPPER(ca_state), ' ', ca_zip) AS formatted_state_zip
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_college_count,
        CHAR_LENGTH(cd_credit_rating) AS credit_length
    FROM customer_demographics
),
AggregateData AS (
    SELECT 
        COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_count) AS total_dependents,
        SUM(cd.cd_dep_college_count) AS total_college_dependents
    FROM AddressParts ca
    JOIN Demographics cd ON (cd.cd_demo_sk = MOD(ca.ca_address_sk, 100)) 
)
SELECT 
    a.unique_addresses,
    a.avg_purchase_estimate,
    a.total_dependents,
    a.total_college_dependents,
    CONCAT('Total Addresses: ', a.unique_addresses, ', Avg Purchase Estimate: ', ROUND(a.avg_purchase_estimate, 2), 
           ', Total Dependents: ', a.total_dependents, ', Total College Dependents: ', a.total_college_dependents) AS summary 
FROM AggregateData a;
