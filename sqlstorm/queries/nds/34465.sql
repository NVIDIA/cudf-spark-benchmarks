
WITH  SalesCTE AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales 
    GROUP BY ws_item_sk
),
CustomerAddressCTE AS (
    SELECT ca_address_sk,
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM customer_address
),
FilteredCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           ca.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerAddressCTE ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_gender = 'F' AND 
          cd.cd_marital_status = 'M' AND 
          (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) > 5
)
SELECT f.c_customer_sk,
       f.c_first_name,
       f.c_last_name,
       f.full_address,
       COALESCE(s.total_sales, 0) AS total_sales
FROM FilteredCustomers f
LEFT JOIN SalesCTE s ON f.c_customer_sk = s.ws_item_sk
WHERE f.c_customer_sk NOT IN (
    SELECT cr_returning_customer_sk 
    FROM catalog_returns
    WHERE cr_return_quantity > 0
)
ORDER BY total_sales DESC;
