
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS avg_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    ss.total_orders,
    ss.total_spent,
    ss.avg_order_value,
    address_info.full_address,
    address_info.ca_city,
    address_info.ca_state,
    address_info.ca_zip,
    address_info.ca_country
FROM CustomerSummary cs
LEFT JOIN SalesSummary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
JOIN AddressInfo address_info ON cs.full_address = address_info.full_address
WHERE cs.cd_marital_status = 'M' AND cs.cd_gender = 'M'
ORDER BY ss.total_spent DESC;
