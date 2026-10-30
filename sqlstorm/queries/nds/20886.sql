
WITH RecursiveAddress AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 
           ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS CityRank
    FROM customer_address
    WHERE ca_country = 'USA'
),
CustomerReturns AS (
    SELECT sr_customer_sk, COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
           COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesSummary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS sales_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(SUM(s.total_sales), 0) AS total_web_sales,
           COALESCE(SUM(r.total_returns), 0) AS total_returns
    FROM customer c
    LEFT JOIN SalesSummary s ON c.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING COALESCE(SUM(s.total_sales), 0) > 10000 AND 
           COALESCE(COUNT(DISTINCT s.ws_bill_customer_sk), 0) < 5
),
FinalReport AS (
    SELECT hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name,
           ra.ca_city, ra.ca_state, ra.ca_country,
           RANK() OVER (ORDER BY hvc.total_web_sales DESC) AS sales_rank
    FROM HighValueCustomers hvc
    JOIN RecursiveAddress ra ON hvc.c_customer_sk = ra.ca_address_sk
)
SELECT f.sales_rank, f.c_first_name, f.c_last_name, 
       f.ca_city, f.ca_state, f.ca_country,
       CASE 
           WHEN f.sales_rank <= 10 THEN 'Top Customer'
           WHEN f.sales_rank <= 50 THEN 'Mid-tier Customer'
           ELSE 'Low-tier Customer'
       END AS customer_tier
FROM FinalReport f
WHERE f.ca_city IS NOT NULL
  AND f.ca_state IS NOT NULL
  AND f.ca_country IS NOT NULL
ORDER BY f.sales_rank;
