
WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FilteredReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_return_amt,
        cr.total_returns,
        cr.rank,
        cd.cd_gender,
        cd.cd_marital_status,
        md.hd_income_band_sk,
        CASE 
            WHEN cr.total_return_amt IS NULL THEN 0 
            ELSE cr.total_return_amt 
        END AS adjusted_return_amt
    FROM 
        CustomerReturns cr
    LEFT JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics md ON c.c_current_hdemo_sk = md.hd_demo_sk
    WHERE 
        cr.rank <= 10
),
AverageReturns AS (
    SELECT 
        AVG(adjusted_return_amt) AS average_return 
    FROM 
        FilteredReturns
)
SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    fr.hd_income_band_sk,
    COUNT(fr.sr_customer_sk) AS num_customers,
    SUM(fr.adjusted_return_amt) AS total_adjusted_returns,
    AVG(fr.adjusted_return_amt) AS avg_adjusted_return,
    ar.average_return
FROM 
    FilteredReturns fr
CROSS JOIN 
    AverageReturns ar
GROUP BY 
    fr.cd_gender, 
    fr.cd_marital_status, 
    fr.hd_income_band_sk,
    ar.average_return
HAVING 
    SUM(fr.adjusted_return_amt) > ar.average_return
ORDER BY 
    total_adjusted_returns DESC
LIMIT 20;
