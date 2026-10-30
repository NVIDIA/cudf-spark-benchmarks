
WITH CustomerData AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status, 
           ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
GenderSales AS (
    SELECT cd.cd_gender, 
           SUM(sd.total_sales) AS gender_sales_total, 
           SUM(sd.order_count) AS gender_order_count
    FROM CustomerData cd
    JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY cd.cd_gender
),
CitySales AS (
    SELECT cd.ca_city,
           SUM(sd.total_sales) AS city_sales_total,
           COUNT(sd.ws_bill_customer_sk) AS customer_count
    FROM CustomerData cd
    JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY cd.ca_city
)
SELECT gs.cd_gender, 
       gs.gender_sales_total, 
       gs.gender_order_count, 
       cs.ca_city, 
       cs.city_sales_total, 
       cs.customer_count
FROM GenderSales gs
CROSS JOIN CitySales cs
ORDER BY gs.cd_gender, cs.ca_city;
