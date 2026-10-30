
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_refund,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        AVG(ws_net_paid_inc_tax) AS average_paid,
        MAX(ws_sales_price) AS max_price,
        MIN(ws_sales_price) AS min_price
    FROM web_sales
    GROUP BY ws_item_sk
),
IncomeReturns AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_refunded
    FROM household_demographics hd
    JOIN store_returns sr ON hd.hd_demo_sk = sr.sr_cdemo_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT 
    ca.ca_address_id, 
    ca.ca_city,
    cr.total_returned,
    cs.total_sold,
    td.total_refunded,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cs.total_sold > 0 THEN (cr.total_returned * 1.0 / cs.total_sold) 
        ELSE NULL 
    END AS return_ratio,
    (SELECT COUNT(*) 
     FROM TotalSales ts WHERE ts.ws_item_sk = cs.ws_item_sk AND ts.total_sold > 0) AS sales_count,
    CASE 
        WHEN cd.cd_credit_rating IS NOT NULL THEN cd.cd_credit_rating || ' rank: ' || cd.gender_rank 
        ELSE 'Undefined rank'
    END AS combined_info
FROM customer_address ca
LEFT JOIN RankedReturns cr ON cr.sr_item_sk = ca.ca_address_sk
JOIN TotalSales cs ON cs.ws_item_sk = cr.sr_item_sk
JOIN CustomerData cd ON cd.c_customer_sk = ca.ca_address_sk
JOIN IncomeReturns td ON td.hd_income_band_sk = cr.total_returned
WHERE ca.ca_state IS NOT NULL
  AND ca.ca_country = 'US'
  AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S')
ORDER BY return_ratio DESC NULLS LAST, cd.c_first_name ASC;
