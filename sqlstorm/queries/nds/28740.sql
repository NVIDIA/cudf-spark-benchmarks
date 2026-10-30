
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
),
Sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS number_of_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ca.ca_address_sk,
    ca.full_address,
    cd.gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    s.total_sales,
    s.number_of_sales,
    ca.ca_city,
    ca.ca_state
FROM RankedAddresses ca
JOIN CustomerDemographics cd ON ca.address_rank = cd.cd_demo_sk
LEFT JOIN Sales s ON cd.cd_demo_sk = s.ws_bill_customer_sk
WHERE ca.ca_state = 'CA'
AND s.total_sales > 1000
ORDER BY ca.ca_city, ca.full_address;
