
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
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
        NULLIF(cd.cd_credit_rating, 'N/A') AS credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        coalesce(rr.total_return_quantity, 0) AS total_return_quantity,
        coalesce(rr.total_return_amt, 0) AS total_return_amt
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        RankedReturns rr ON cd.c_customer_sk = rr.sr_customer_sk AND rr.rn = 1
    WHERE 
        cd.cd_purchase_estimate > 1000
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.total_return_quantity,
    hvc.total_return_amt,
    CASE 
        WHEN hvc.total_return_amt > 500 THEN 'High Return'
        WHEN hvc.total_return_amt BETWEEN 200 AND 500 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category,
    CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS full_name
FROM 
    HighValueCustomers hvc
WHERE 
    hvc.total_return_quantity > 5 AND hvc.total_return_amt IS NOT NULL
ORDER BY 
    hvc.total_return_amt DESC
LIMIT 10;
