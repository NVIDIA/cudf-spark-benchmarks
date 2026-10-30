
WITH CustomerReturns AS (
    SELECT 
        sr_store_sk,
        sr_customer_sk,
        SUM(CASE WHEN sr_returned_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk, sr_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopReturningCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        ci.full_name,
        cr.total_returns,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        ROW_NUMBER() OVER (ORDER BY cr.total_returned_amount DESC) AS rn
    FROM 
        CustomerReturns AS cr
    JOIN 
        CustomerInfo AS ci ON cr.sr_customer_sk = ci.c_customer_sk
    WHERE 
        cr.total_returns > 0
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.purchase_estimate,
    COALESCE(trc.total_returns, 0) AS total_returns,
    COALESCE(trc.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(trc.total_returned_amount, 0) AS total_returned_amount
FROM 
    CustomerInfo AS ci
LEFT JOIN 
    TopReturningCustomers AS trc ON ci.c_customer_sk = trc.sr_customer_sk
WHERE 
    ci.cd_gender = 'F' AND 
    ci.purchase_estimate > 1000
ORDER BY 
    ci.purchase_estimate DESC
LIMIT 10;
