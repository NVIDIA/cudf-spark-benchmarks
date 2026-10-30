
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk, 
        sr_returned_date_sk, 
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_value,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY COUNT(*) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk, sr_returned_date_sk
),
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(h.hd_income_band_sk, -1) AS income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
HighReturnCustomers AS (
    SELECT 
        r.sr_customer_sk,
        r.total_returns,
        r.total_return_value,
        ci.income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY ci.income_band_sk ORDER BY r.total_return_value DESC) AS income_rank
    FROM 
        RankedReturns r
    JOIN 
        CustomerIncome ci ON r.sr_customer_sk = ci.c_customer_sk
    WHERE 
        r.return_rank = 1 AND r.total_return_value > 1000
),
IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk, 
        COUNT(*) AS customer_count
    FROM 
        HighReturnCustomers hrc
    JOIN 
        income_band ib ON hrc.income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.customer_count,
    COALESCE(NTH_VALUE(ib.customer_count, 1) OVER (ORDER BY ib.ib_income_band_sk), 0) AS previous_band_count,
    CASE 
        WHEN ib.customer_count IS NULL OR ib.customer_count = 0 THEN 'No High Return Customers in This Band'
        ELSE 'High Return Customer Present'
    END AS status
FROM 
    IncomeBands ib
FULL OUTER JOIN 
    income_band ibs ON ib.ib_income_band_sk = ibs.ib_income_band_sk
WHERE 
    ibs.ib_lower_bound IS NOT NULL
ORDER BY 
    ib.ib_income_band_sk;
