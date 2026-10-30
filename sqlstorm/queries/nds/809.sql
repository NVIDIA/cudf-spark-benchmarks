
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_amt DESC) AS return_rank
    FROM 
        store_returns
),
TotalReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_estimation_band,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        TotalReturns tr ON c.c_customer_sk = tr.sr_customer_sk
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.purchase_estimation_band,
    COALESCE(rr.return_rank, 0) AS highest_return_rank
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedReturns rr ON cs.c_customer_sk = rr.sr_customer_sk AND rr.return_rank = 1
WHERE 
    cs.total_return_amt > (SELECT AVG(total_return_amt) FROM TotalReturns)
    AND cs.cd_credit_rating IS NOT NULL
ORDER BY 
    cs.purchase_estimation_band, 
    highest_return_rank;
