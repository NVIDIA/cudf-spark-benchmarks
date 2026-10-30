
WITH CustomerAddress AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
           ca_city, 
           ca_state, 
           ca_zip, 
           ca_country
    FROM customer_address
),
CustomerDemographics AS (
    SELECT cd_demo_sk,
           cd_gender,
           cd_marital_status,
           cd_education_status,
           cd_purchase_estimate,
           cd_credit_rating,
           cd_dep_count
    FROM customer_demographics
),
DateDim AS (
    SELECT d_date_sk,
           d_date,
           d_month_seq,
           d_year,
           d_day_name
    FROM date_dim
),
SalesData AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_item_sk
),
DiscountedSales AS (
    SELECT s.customer_sk,
           s.total_sales * 0.9 AS discounted_sales,
           c.cd_gender,
           c.cd_marital_status,
           c.cd_education_status,
           c.cd_purchase_estimate,
           a.full_address,
           d.d_date,
           d.d_month_seq
    FROM SalesData s
    JOIN CustomerDemographics c ON s.customer_sk = c.cd_demo_sk
    JOIN CustomerAddress a ON s.customer_sk = a.ca_address_sk
    JOIN DateDim d ON d.d_date = DATE '2002-10-01'
)
SELECT ds.customer_sk,
       SUM(ds.discounted_sales) AS total_discounted_sales,
       COUNT(DISTINCT ds.customer_sk) AS unique_customers,
       ds.cd_gender,
       ds.cd_marital_status,
       ds.cd_education_status,
       ds.cd_purchase_estimate,
       ds.full_address
FROM DiscountedSales ds
GROUP BY ds.customer_sk, ds.cd_gender, ds.cd_marital_status, ds.cd_education_status, ds.cd_purchase_estimate, ds.full_address
ORDER BY total_discounted_sales DESC
LIMIT 100;
