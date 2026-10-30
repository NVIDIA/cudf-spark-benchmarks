
WITH FilteredCustomer AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           c.c_birth_country,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    WHERE c.c_birth_country LIKE 'United%' 
      AND c.c_preferred_cust_flag = 'Y'
), 
AddressDetails AS (
    SELECT ca.ca_address_sk,
           ca.ca_city,
           ca.ca_state,
           ca.ca_zip,
           ca.ca_country,
           ca.ca_street_name,
           ca.ca_street_number,
           ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_address_sk) AS city_rank
    FROM customer_address ca
    WHERE ca.ca_country <> 'USA'
), 
SalesSummary AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN FilteredCustomer fc ON ws.ws_bill_customer_sk = fc.c_customer_sk
    GROUP BY ws.ws_bill_customer_sk
)
SELECT fc.c_customer_sk,
       fc.full_name,
       ad.ca_city,
       ad.ca_state,
       ad.ca_zip,
       ss.total_profit,
       ss.total_orders
FROM FilteredCustomer fc
JOIN AddressDetails ad ON ad.city_rank = 1
JOIN SalesSummary ss ON ss.ws_bill_customer_sk = fc.c_customer_sk
ORDER BY ss.total_profit DESC;
