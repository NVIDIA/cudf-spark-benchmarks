
WITH AddressDetails AS (
    SELECT ca_address_sk, 
           TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                       CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                       THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS full_address,
           ca_city, ca_state, ca_zip
    FROM customer_address
),
CustomerWithAddresses AS (
    SELECT c.c_customer_sk, 
           CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
           a.full_address, a.ca_city, a.ca_state, a.ca_zip
    FROM customer c
    JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSalesDetails AS (
    SELECT cwa.*, 
           COALESCE(sd.total_net_profit, 0) AS total_net_profit
    FROM CustomerWithAddresses cwa
    LEFT JOIN SalesData sd ON cwa.c_customer_sk = sd.customer_sk
)
SELECT full_name, full_address, ca_city, ca_state, ca_zip, total_net_profit
FROM CustomerSalesDetails
WHERE total_net_profit > 1000
ORDER BY total_net_profit DESC, full_name ASC
LIMIT 100;
