WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt,
        COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = 'High' 
),
MonthlyReturns AS (
    SELECT 
        d.d_month_seq,
        SUM(sr_return_quantity) AS total_monthly_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    CASE 
        WHEN cr.total_returned_quantity > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_returns,
    mt.total_monthly_returns,
    ROW_NUMBER() OVER (PARTITION BY hvc.hd_income_band_sk ORDER BY cr.total_returned_amt DESC) AS income_band_rank
FROM HighValueCustomers hvc
LEFT JOIN CustomerReturns cr ON hvc.c_customer_sk = cr.sr_customer_sk
LEFT JOIN MonthlyReturns mt ON mt.d_month_seq = EXTRACT(MONTH FROM cast('2002-10-01' as date))
WHERE hvc.cd_marital_status = 'M' 
  AND hvc.hd_income_band_sk IS NOT NULL
ORDER BY hvc.c_last_name, hvc.c_first_name;