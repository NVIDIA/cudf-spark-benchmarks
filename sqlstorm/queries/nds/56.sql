
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighReturnCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cr.total_return_amt,
        cr.total_returns,
        cr.avg_return_quantity
    FROM CustomerDetails cd
    JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_return_amt > (
        SELECT AVG(total_return_amt) 
        FROM CustomerReturns
    )
)
SELECT 
    hrc.c_first_name,
    hrc.c_last_name,
    hrc.total_return_amt,
    hrc.total_returns,
    hrc.avg_return_quantity,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    DENSE_RANK() OVER (ORDER BY hrc.total_return_amt DESC) AS return_rank
FROM HighReturnCustomers hrc
JOIN CustomerDetails cd ON hrc.c_customer_sk = cd.c_customer_sk
ORDER BY hrc.total_return_amt DESC
LIMIT 10;
