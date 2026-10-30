
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
ReturnStatistics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS returns_count,
        COALESCE(SUM(sr_return_amt), 0) AS total_returns_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    cs.total_returned_quantity,
    rs.returns_count,
    rs.total_returns_amount,
    CASE 
        WHEN rs.total_returns_amount > 0 THEN 'Returned'
        ELSE 'No Returns'
    END AS return_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerReturns cs ON hvc.c_customer_sk = cs.sr_customer_sk
LEFT JOIN 
    ReturnStatistics rs ON hvc.c_customer_sk = rs.c_customer_sk
WHERE 
    hvc.rank <= 10
ORDER BY 
    hvc.cd_gender, hvc.cd_purchase_estimate DESC;
