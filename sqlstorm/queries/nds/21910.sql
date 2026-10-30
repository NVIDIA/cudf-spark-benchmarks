
WITH RecursiveIncome AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk IS NOT NULL
),
CustomerInfo AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           ca.ca_city, 
           cd.cd_gender,
           CASE 
               WHEN cd.cd_marital_status = 'M' THEN 'Married'
               ELSE 'Single/Unknown'
           END AS marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           (SELECT COUNT(*) FROM customer c2 WHERE c2.c_current_cdemo_sk = c.c_current_cdemo_sk) AS same_demo_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TotalSales AS (
    SELECT ci.c_customer_id,
           ci.ca_city,
           ci.marital_status,
           ci.cd_gender,
           si.total_sales,
           si.order_count,
           RANK() OVER (ORDER BY COALESCE(si.total_sales, 0) DESC, ci.c_customer_id) AS rank
    FROM CustomerInfo ci
    LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.customer_sk
),
IncomeDistribution AS (
    SELECT ci.c_customer_id,
           ci.marital_status,
           ci.ca_city,
           SUM(CASE WHEN ci.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound THEN 1 END) AS in_income_band_count
    FROM CustomerInfo ci
    JOIN RecursiveIncome ib ON ci.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    GROUP BY ci.c_customer_id, ci.marital_status, ci.ca_city
)

SELECT td.c_customer_id,
       td.ca_city,
       td.marital_status,
       COALESCE(td.total_sales, 0) AS total_sales,
       COALESCE(td.order_count, 0) AS order_count,
       id.in_income_band_count
FROM TotalSales td
LEFT JOIN IncomeDistribution id ON td.c_customer_id = id.c_customer_id
WHERE (td.total_sales IS NOT NULL OR id.in_income_band_count IS NOT NULL)
  AND (td.rank <= 100 OR id.in_income_band_count > 5)
ORDER BY td.total_sales DESC, td.c_customer_id;
