
WITH ProcessedAddresses AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
FilteredDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_credit_rating = 'High' THEN 'Gold'
            WHEN cd_credit_rating = 'Medium' THEN 'Silver'
            ELSE 'Bronze' 
        END AS credit_level
    FROM customer_demographics
    WHERE cd_purchase_estimate > 50000
),
SalesSummary AS (
    SELECT
        ws_bill_addr_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_items_sold,
        SUM(ws_net_paid) AS total_revenue
    FROM web_sales
    GROUP BY ws_bill_addr_sk
)
SELECT
    a.ca_address_sk,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    d.cd_gender,
    d.credit_level,
    s.total_orders,
    s.total_items_sold,
    s.total_revenue
FROM ProcessedAddresses a
JOIN FilteredDemographics d ON a.ca_address_sk = d.cd_demo_sk
LEFT JOIN SalesSummary s ON a.ca_address_sk = s.ws_bill_addr_sk
ORDER BY s.total_revenue DESC, a.ca_city, a.ca_state;
