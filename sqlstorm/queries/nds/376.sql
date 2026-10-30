
WITH CustomerReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_reason_sk IS NOT NULL
    GROUP BY 
        cr.cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        (SELECT SUM(de.cd_dep_count) 
         FROM customer_demographics de 
         WHERE de.cd_demo_sk = c.c_current_cdemo_sk) AS total_dependents
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_return_amount DESC) AS rank_by_return_amount
FROM 
    CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    cd.cd_gender IS NOT NULL
    AND cd.cd_marital_status = 'M'
    AND ib.ib_lower_bound IS NOT NULL
ORDER BY 
    total_return_amount DESC, 
    cd.c_customer_sk
LIMIT 100;
