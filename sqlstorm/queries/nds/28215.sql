
WITH AddressConcatenation AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
DemographicsAggregated AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS average_purchase_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),
SalesDetail AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_quantity) AS average_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT
    A.ca_address_sk,
    A.full_address,
    D.cd_gender,
    D.cd_marital_status,
    S.total_orders,
    S.total_sales,
    S.average_quantity,
    CASE 
        WHEN D.cd_gender = 'M' THEN 'Male Customer'
        WHEN D.cd_gender = 'F' THEN 'Female Customer'
        ELSE 'Other Gender Customer'
    END AS customer_gender_description
FROM AddressConcatenation A
JOIN DemographicsAggregated D ON A.ca_address_sk = D.cd_demo_sk
LEFT JOIN SalesDetail S ON S.ws_bill_customer_sk = A.ca_address_sk
WHERE A.ca_city LIKE '%Springfield%'
  AND D.highest_credit_rating = 'Excellent'
ORDER BY total_sales DESC, A.full_address;
