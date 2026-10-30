
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
TopReturningCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        cu.c_first_name,
        cu.c_last_name,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.buy_potential,
        cu.hd_income_band_sk
    FROM 
        RankedReturns cr
    JOIN 
        CustomerDetails cu ON cr.sr_customer_sk = cu.c_customer_sk
    WHERE 
        cr.rank <= 10
)
SELECT 
    trc.c_first_name,
    trc.c_last_name,
    trc.cd_gender,
    trc.cd_marital_status,
    trc.total_returns,
    trc.total_return_amount,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    TopReturningCustomers trc
LEFT JOIN 
    income_band ib ON trc.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    trc.total_return_amount > 100 AND 
    (trc.cd_gender = 'F' OR trc.cd_marital_status = 'M')
ORDER BY 
    trc.total_return_amount DESC
LIMIT 20;
