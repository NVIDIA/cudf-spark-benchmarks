
WITH AddressParts AS (
    SELECT ca_address_sk, 
           CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
                  CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
           TRIM(ca_city) AS city,
           TRIM(ca_state) AS state,
           TRIM(ca_zip) AS zip,
           TRIM(ca_country) AS country
    FROM customer_address
), 
CustomerDetails AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           d.d_date AS first_purchase_date,
           a.full_address, 
           a.city, 
           a.state, 
           a.zip, 
           a.country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE cd.cd_gender = 'M' 
      AND cd.cd_marital_status = 'M'
), 
SalesSummary AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_spent,
           COUNT(ws_order_number) AS orders_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT cd.c_first_name, 
       cd.c_last_name, 
       cd.first_purchase_date,
       cd.full_address, 
       cd.city, 
       cd.state, 
       cd.zip, 
       cd.country,
       ss.total_spent, 
       ss.orders_count
FROM CustomerDetails cd
LEFT JOIN SalesSummary ss ON cd.c_customer_sk = ss.customer_sk
ORDER BY ss.total_spent DESC
LIMIT 10;
