
WITH  SalesHierarchy AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY ws_bill_customer_sk
    UNION ALL
    SELECT sr_customer_sk, 
           SUM(sr_return_amt) AS total_sales
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY sr_customer_sk
),
RankedSales AS (
    SELECT customer_sk, 
           total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesHierarchy
),
CustomerDemographics AS (
    SELECT c.c_customer_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT cs.customer_sk, 
           SUM(cs.total_sales) AS overall_sales,
           COUNT(DISTINCT cs.customer_sk) AS total_customers
    FROM RankedSales cs
    JOIN CustomerDemographics cd ON cs.customer_sk = cd.c_customer_sk
    GROUP BY cs.customer_sk
)
SELECT sd.customer_sk, 
       sd.overall_sales,
       CASE 
           WHEN cd.cd_gender = 'M' THEN 'Male'
           WHEN cd.cd_gender = 'F' THEN 'Female'
           ELSE 'Other' 
       END AS gender,
       CASE 
           WHEN sd.overall_sales > 5000 THEN 'High Value'
           WHEN sd.overall_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
           ELSE 'Low Value' 
       END AS customer_value,
       CASE
           WHEN cd.cd_credit_rating IS NOT NULL THEN cd.cd_credit_rating
           ELSE 'unknown' 
       END AS credit_rating
FROM SalesData sd
LEFT JOIN CustomerDemographics cd ON sd.customer_sk = cd.c_customer_sk
WHERE sd.total_customers > 10
ORDER BY sd.overall_sales DESC, customer_sk ASC
LIMIT 50;
