
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number != '' 
                    THEN CONCAT(', Suite ', TRIM(ca_suite_number)) ELSE '' END) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS FullName,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.FullAddress,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS TotalNetProfit,
        COUNT(ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_net_paid_inc_tax) AS AvgSpent
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ci.FullName,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ss.TotalNetProfit,
    ss.TotalOrders,
    ss.AvgSpent
FROM CustomerInfo ci
JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE ci.ca_state = 'CA'
ORDER BY ss.TotalNetProfit DESC
LIMIT 10;
