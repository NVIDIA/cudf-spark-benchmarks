
WITH AddressDetails AS (
    SELECT ca_address_sk, 
           ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
           ca_city, 
           ca_state 
    FROM customer_address 
),
CustomerFullNames AS (
    SELECT c_customer_sk, 
           c_first_name || ' ' || c_last_name AS full_name, 
           cd_gender,
           cd_marital_status 
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesStatistics AS (
    SELECT ws_bill_customer_sk, 
           COUNT(ws_order_number) AS total_orders, 
           SUM(ws_net_profit) AS total_profit 
    FROM web_sales 
    GROUP BY ws_bill_customer_sk
)
SELECT c.full_name, 
       a.full_address, 
       c.cd_gender, 
       c.cd_marital_status, 
       s.total_orders, 
       s.total_profit 
FROM CustomerFullNames c
JOIN AddressDetails a ON c.c_customer_sk = a.ca_address_sk
JOIN SalesStatistics s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE c.cd_gender = 'M' 
  AND s.total_orders > 5
ORDER BY s.total_profit DESC
LIMIT 100;
