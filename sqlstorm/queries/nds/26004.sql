
WITH AddressDetails AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                  COALESCE(CONCAT(' ', ca_suite_number), '')) AS full_address,
           ca_city, 
           ca_state, 
           ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT ws_bill_customer_sk AS customer_id, 
           SUM(ws_ext_sales_price) AS total_spent,
           COUNT(ws_order_number) AS number_of_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT cu.full_name, 
           cu.cd_gender, 
           cu.cd_marital_status, 
           ad.full_address, 
           ad.ca_city, 
           ad.ca_state, 
           ad.ca_zip, 
           ss.total_spent, 
           ss.number_of_orders
    FROM CustomerDetails cu
    JOIN AddressDetails ad ON cu.c_customer_sk = ad.ca_address_sk
    JOIN SalesSummary ss ON cu.c_customer_sk = ss.customer_id
)
SELECT full_name, 
       cd_gender, 
       cd_marital_status, 
       full_address, 
       ca_city, 
       ca_state, 
       ca_zip, 
       total_spent, 
       number_of_orders,
       CASE 
           WHEN total_spent > 1000 THEN 'High Roller'
           WHEN total_spent BETWEEN 500 AND 1000 THEN 'Middle Class'
           ELSE 'Budget Buyer'
       END AS customer_segment
FROM CombinedData
WHERE cd_gender = 'F' 
  AND ca_state = 'CA'
ORDER BY total_spent DESC
LIMIT 10;
