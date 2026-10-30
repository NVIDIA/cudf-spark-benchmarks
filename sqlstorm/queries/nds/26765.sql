
WITH AddressFilter AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS FullAddress,
           ca_city,
           ca_state,
           ca_zip
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY') 
      AND ca_zip LIKE '9%'
),
Demographics AS (
    SELECT cd_demo_sk, 
           CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS DemographicProfile,
           cd_purchase_estimate,
           cd_credit_rating
    FROM customer_demographics
    WHERE cd_purchase_estimate > 5000
),
SalesData AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_paid) AS TotalSales,
           COUNT(DISTINCT ws_order_number) AS OrdersCount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FinalOutput AS (
    SELECT c.c_customer_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS CustomerName,
           af.FullAddress,
           d.DemographicProfile,
           sd.TotalSales,
           sd.OrdersCount
    FROM customer c
    JOIN AddressFilter af ON c.c_current_addr_sk = af.ca_address_sk
    JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    WHERE sd.TotalSales IS NOT NULL
)
SELECT *
FROM FinalOutput
ORDER BY TotalSales DESC
LIMIT 50;
