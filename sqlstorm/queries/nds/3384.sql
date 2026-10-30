
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'LOW'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS purchase_estimate_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStatistics AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.purchase_estimate_category,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0.0) AS total_returned_amount,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender, ci.purchase_estimate_category ORDER BY COALESCE(cr.total_returns, 0) DESC) AS return_rank
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        CustomerReturns cr ON ci.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.purchase_estimate_category,
    r.total_returns,
    r.total_returned_amount,
    r.total_returned_quantity
FROM 
    ReturnStatistics r
WHERE 
    r.return_rank <= 10
ORDER BY 
    r.purchase_estimate_category, r.total_returns DESC;
