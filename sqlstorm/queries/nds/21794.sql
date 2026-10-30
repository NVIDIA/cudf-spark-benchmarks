
WITH RecursiveIncome AS (
    SELECT hd_demo_sk, ib_income_band_sk, hd_buy_potential, hd_dep_count,
           ROW_NUMBER() OVER (PARTITION BY hd_demo_sk ORDER BY hd_buy_potential) AS income_rank
    FROM household_demographics h
    LEFT JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
), 
CustomerReturns AS (
    SELECT 
        s.ss_customer_sk,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr_returned_date_sk) AS unique_return_days
    FROM store_sales s
    LEFT JOIN store_returns sr ON s.ss_item_sk = sr.sr_item_sk
    GROUP BY s.ss_customer_sk
),
RecentCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           DENSE_RANK() OVER (ORDER BY c.c_first_shipto_date_sk DESC) AS customer_rank
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    ri.ib_income_band_sk,
    COALESCE(cr.total_returns, 0) AS total_returns,
    cr.unique_return_days,
    CASE 
        WHEN cr.total_returns = 0 THEN 'No Returns'
        WHEN cr.total_returns <= 5 THEN 'Few Returns'
        ELSE 'Frequent Returns' 
    END AS return_category
FROM RecentCustomers rc
JOIN customer_demographics cd ON rc.c_customer_sk = cd.cd_demo_sk
JOIN RecursiveIncome ri ON cd.cd_demo_sk = ri.hd_demo_sk AND ri.income_rank = 1
LEFT JOIN CustomerReturns cr ON rc.c_customer_sk = cr.ss_customer_sk
WHERE rc.customer_rank <= 10 
  AND (COALESCE(ri.ib_income_band_sk, -1) BETWEEN 0 AND 5 OR ri.hd_buy_potential LIKE '%High%')
ORDER BY return_category, rc.c_first_name ASC;
