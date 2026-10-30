
WITH CTE_CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CTE_StoreReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_store_returns,
        SUM(sr_return_amt) AS total_store_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
CTE_CustomerDemographics AS (
    SELECT 
        cu.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Unknown'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buying_potential
    FROM customer cu
    JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cu.c_current_hdemo_sk
),
CTE_CombinedReturns AS (
    SELECT 
        ccd.c_customer_sk,
        COALESCE(cwr.total_web_returns, 0) AS web_return_count,
        COALESCE(csr.total_store_returns, 0) AS store_return_count,
        ccd.gender, 
        ccd.cd_marital_status, 
        ccd.cd_education_status,
        ccd.buying_potential
    FROM CTE_CustomerDemographics ccd
    LEFT JOIN CTE_CustomerReturns cwr ON ccd.c_customer_sk = cwr.wr_returning_customer_sk
    LEFT JOIN CTE_StoreReturns csr ON ccd.c_customer_sk = csr.sr_customer_sk
)
SELECT 
    cb.c_customer_sk,
    cb.gender,
    cb.cd_marital_status,
    cb.cd_education_status,
    cb.buying_potential,
    cb.web_return_count,
    cb.store_return_count,
    ROW_NUMBER() OVER (PARTITION BY cb.gender ORDER BY (cb.web_return_count + cb.store_return_count) DESC) AS rank
FROM CTE_CombinedReturns cb
WHERE (cb.web_return_count > 0 OR cb.store_return_count > 0)
ORDER BY cb.gender, rank
LIMIT 100;
