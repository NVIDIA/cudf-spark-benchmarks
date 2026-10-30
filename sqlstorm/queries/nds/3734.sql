
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS Rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TotalReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS TotalStoreReturns,
        SUM(sr_return_amt_inc_tax) AS TotalStoreReturnAmt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
StoreReturnsByCustomer AS (
    SELECT 
        c.c_customer_id,
        COALESCE(tr.TotalStoreReturns, 0) AS TotalStoreReturns,
        COALESCE(tr.TotalStoreReturnAmt, 0) AS TotalStoreReturnAmt
    FROM 
        customer c
    LEFT JOIN 
        TotalReturns tr ON c.c_customer_sk = tr.sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.cd_marital_status,
        r.cd_purchase_estimate,
        sr.TotalStoreReturns,
        sr.TotalStoreReturnAmt
    FROM 
        RankedCustomers r
    JOIN 
        StoreReturnsByCustomer sr ON r.c_customer_id = sr.c_customer_id
    WHERE 
        r.Rank <= 10
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    hvc.TotalStoreReturns,
    hvc.TotalStoreReturnAmt,
    CASE 
        WHEN hvc.TotalStoreReturnAmt > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS ReturnStatus
FROM 
    HighValueCustomers hvc
ORDER BY 
    hvc.cd_purchase_estimate DESC,
    hvc.TotalStoreReturnAmt DESC;
