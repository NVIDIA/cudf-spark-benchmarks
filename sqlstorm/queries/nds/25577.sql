
WITH CustomerInfo AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           ca.ca_city, 
           ca.ca_state, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status,
           cd.cd_purchase_estimate
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesData AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS total_spent,
           COUNT(ws_order_number) AS total_orders,
           COUNT(DISTINCT ws_item_sk) AS unique_items_purchased
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
Benchmark AS (
    SELECT ci.full_name, 
           ci.ca_city, 
           ci.ca_state,
           ci.cd_gender, 
           ci.cd_marital_status, 
           ci.cd_education_status, 
           ci.cd_purchase_estimate,
           COALESCE(sd.total_spent, 0) AS total_spent,
           COALESCE(sd.total_orders, 0) AS total_orders,
           COALESCE(sd.unique_items_purchased, 0) AS unique_items_purchased
    FROM CustomerInfo AS ci
    LEFT JOIN SalesData AS sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT AVG(total_spent) AS avg_spent,
       AVG(total_orders) AS avg_orders,
       AVG(unique_items_purchased) AS avg_unique_items
FROM Benchmark
WHERE cd_gender = 'M' AND cd_marital_status = 'S';
