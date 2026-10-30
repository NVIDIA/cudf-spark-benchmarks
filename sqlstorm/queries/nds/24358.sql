
WITH  AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM customer_address
    WHERE ca_state IS NOT NULL
),
IncomeCTE AS (
    SELECT hd_demo_sk, ib_income_band_sk, ROW_NUMBER() OVER (ORDER BY hd_demo_sk) as rn
    FROM household_demographics
    JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    WHERE hd_buy_potential IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        AVG(ss_net_paid_inc_tax) AS avg_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        SUM(CASE WHEN ss_quantity > 0 THEN ss_quantity ELSE 0 END) AS total_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 1 AND 30
    GROUP BY ss_store_sk
),
CustomerReturn AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_return,
        COUNT(sr_ticket_number) AS return_count,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_store_sk
),
FinalSummary AS (
    SELECT 
        A.ca_state,
        A.ca_city,
        COALESCE(S.total_sales, 0) AS total_sales,
        COALESCE(R.total_return, 0) AS total_return,
        COALESCE(S.unique_customers, 0) AS unique_customers,
        COALESCE(S.avg_sales, 0) AS avg_sales,
        COALESCE(R.avg_return_quantity, 0) AS avg_return_quantity,
        (COALESCE(S.total_sales, 0) - COALESCE(R.total_return, 0)) AS net_profit,
        CASE WHEN COALESCE(S.total_sales, 0) = 0 THEN 0 
             ELSE (COALESCE(R.total_return, 0) / COALESCE(S.total_sales, 0)) * 100 END AS return_percentage
    FROM AddressCTE A
    LEFT JOIN SalesSummary S ON A.ca_address_sk = S.ss_store_sk
    LEFT JOIN CustomerReturn R ON A.ca_address_sk = R.sr_store_sk
    WHERE A.rn = 1
)
SELECT 
    fs.ca_state,
    fs.ca_city,
    fs.total_sales,
    fs.total_return,
    fs.unique_customers,
    fs.avg_sales,
    fs.avg_return_quantity,
    fs.net_profit,
    fs.return_percentage,
    ROW_NUMBER() OVER (ORDER BY fs.net_profit DESC) AS rank
FROM FinalSummary fs
WHERE fs.return_percentage IS NOT NULL 
  AND (fs.total_sales > 1000 OR fs.total_return > 100)
ORDER BY fs.ca_state, fs.ca_city;
