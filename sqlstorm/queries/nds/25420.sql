
WITH CustomerData AS (
    SELECT c.c_customer_sk, CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS address,
           ca.ca_city, ca.ca_state, ca.ca_zip, cd.cd_gender, cd.cd_marital_status
    FROM customer AS c
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales AS ws
    GROUP BY ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT cd.*, sd.total_profit, sd.total_orders
    FROM CustomerData AS cd
    LEFT JOIN SalesData AS sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT full_name, address, ca_city, ca_state, ca_zip, cd_gender, cd_marital_status, 
       COALESCE(total_profit, 0) AS total_profit, 
       COALESCE(total_orders, 0) AS total_orders
FROM CombinedData
WHERE ca_state IN ('CA', 'NY')
ORDER BY total_profit DESC, full_name;
