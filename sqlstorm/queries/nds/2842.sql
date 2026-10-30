
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
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
        COALESCE(cd.cd_credit_rating, 'Not Available') AS credit_rating,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStats AS (
    SELECT
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        cr.avg_return_quantity,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.credit_rating
    FROM CustomerReturns cr
    INNER JOIN CustomerDetails cd ON cr.sr_customer_sk = cd.c_customer_sk
),
HighReturnCustomers AS (
    SELECT
        *,
        NTILE(10) OVER (ORDER BY total_return_amount DESC) AS return_decile
    FROM ReturnStats
)
SELECT
    *,
    CASE 
        WHEN return_decile = 1 THEN 'Top 10%' 
        WHEN return_decile = 10 THEN 'Bottom 10%' 
        ELSE 'Middle'
    END AS return_category
FROM HighReturnCustomers
WHERE total_return_amount > (SELECT AVG(total_return_amount) FROM ReturnStats)
ORDER BY total_return_amount DESC;
