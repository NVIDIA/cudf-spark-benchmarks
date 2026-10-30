
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate, 
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS demographic_summary
    FROM customer_demographics
),
CustomerFull AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        d.demographic_summary
    FROM customer c
    JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    c.full_name,
    c.full_address,
    c.demographic_summary,
    COUNT(o.ws_order_number) AS total_orders,
    SUM(o.ws_sales_price) AS total_sales,
    AVG(o.ws_sales_price) AS avg_order_value
FROM CustomerFull c
LEFT JOIN web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
GROUP BY c.full_name, c.full_address, c.demographic_summary
ORDER BY total_sales DESC
LIMIT 50;
