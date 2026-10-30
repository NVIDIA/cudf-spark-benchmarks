
WITH AddressComponents AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                   THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
FilteredAddresses AS (
    SELECT 
        full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_city) AS city_rank
    FROM AddressComponents
    WHERE ca_state = 'CA'
),
Demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        COUNT(*) AS demo_count 
    FROM customer_demographics 
    GROUP BY cd_gender, cd_marital_status, cd_education_status
),
WebSalesAggregated AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    fa.full_address,
    fa.ca_city,
    fa.ca_zip,
    fa.ca_country,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.demo_count,
    wsa.total_profit,
    wsa.order_count
FROM FilteredAddresses fa
JOIN Demographics d ON fa.city_rank <= 5
LEFT JOIN WebSalesAggregated wsa ON wsa.ws_bill_customer_sk = fa.city_rank
WHERE (wsa.total_profit IS NOT NULL AND wsa.total_profit > 0)
ORDER BY fa.ca_city, d.cd_gender;
