
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
    GROUP BY
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        (COALESCE(cr.total_return_amount, 0) / NULLIF(COALESCE(cd.cd_purchase_estimate, 1), 0)) * 100 AS return_percentage
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
)
SELECT
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.gender,
    hvc.marital_status,
    hvc.purchase_estimate,
    hvc.total_returns,
    hvc.total_return_amount,
    hvc.return_percentage
FROM
    HighValueCustomers hvc
WHERE
    hvc.return_percentage > 10
ORDER BY
    hvc.return_percentage DESC
LIMIT 10;
