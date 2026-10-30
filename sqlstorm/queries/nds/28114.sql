WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerCounts AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        c.customer_count,
        s.total_net_profit,
        s.total_orders
    FROM AddressDetails a
    JOIN CustomerCounts c ON a.ca_city = c.cd_gender 
    LEFT JOIN SalesData s ON s.ws_bill_customer_sk = a.ca_address_sk
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    COALESCE(customer_count, 0) AS customer_count,
    COALESCE(total_net_profit, 0) AS total_net_profit,
    COALESCE(total_orders, 0) AS total_orders
FROM CombinedData
WHERE ca_state = 'CA'
ORDER BY total_net_profit DESC, customer_count DESC
LIMIT 100;