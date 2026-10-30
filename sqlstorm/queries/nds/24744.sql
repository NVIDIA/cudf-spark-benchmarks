
WITH  CustomerReturns AS (
    SELECT sr_returned_date_sk, sr_return_time_sk, sr_item_sk, sr_customer_sk, sr_return_quantity, sr_return_amt_inc_tax,
           ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
), AggregateReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_quantity) AS total_returned, 
           AVG(sr_return_amt_inc_tax) AS avg_return_amt, 
           COUNT(*) AS return_count
    FROM CustomerReturns
    WHERE rn <= 5
    GROUP BY sr_customer_sk
), CustomerDemographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_purchase_estimate, 
           cd_credit_rating, cd_dep_count, 
           CASE WHEN cd_purchase_estimate > 1000 THEN 'High Value' ELSE 'Regular' END AS customer_value
    FROM customer_demographics
), CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.customer_value, ar.total_returned, ar.avg_return_amt
    FROM customer c
    LEFT JOIN AggregateReturns ar ON c.c_customer_sk = ar.sr_customer_sk
    LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), ActiveStores AS (
    SELECT s_store_sk, s_store_name, s_state
    FROM store
    WHERE s_closed_date_sk IS NULL
), ReturnSummary AS (
    SELECT cd.customer_value, COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
           AVG(properties.total_returned) AS avg_returned, COUNT(properties.total_returned) AS total_return_count
    FROM CustomerDetails cd
    LEFT JOIN AggregateReturns properties ON cd.c_customer_sk = properties.sr_customer_sk
    GROUP BY cd.customer_value
)
SELECT r.customer_value,
       COALESCE(r.customer_count, 0) AS customer_count,
       ROUND(COALESCE(r.avg_returned, 0), 2) AS avg_returned,
       COALESCE(c.active_store_count, 0) AS active_store_count
FROM ReturnSummary r
FULL OUTER JOIN (
    SELECT COUNT(DISTINCT s_store_sk) AS active_store_count
    FROM ActiveStores
) c ON 1=1
WHERE r.customer_count IS NULL OR r.customer_count > 10
ORDER BY r.customer_value DESC NULLS LAST;
