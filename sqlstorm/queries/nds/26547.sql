
WITH AddressDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
IncomeDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ad.full_name,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    id.cd_gender,
    id.cd_marital_status,
    id.ib_lower_bound AS income_lower_bound,
    id.ib_upper_bound AS income_upper_bound,
    COALESCE(sd.total_spent, 0) AS total_spent,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(sd.avg_order_value, 0) AS avg_order_value
FROM AddressDetails ad
JOIN IncomeDemographics id ON ad.c_customer_sk = id.cd_demo_sk
LEFT JOIN SalesData sd ON ad.c_customer_sk = sd.ws_bill_customer_sk
WHERE ad.ca_state = 'CA'
ORDER BY total_spent DESC
LIMIT 100;
