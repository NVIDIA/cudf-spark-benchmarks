WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returns,
        cr.total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_return_amount DESC) AS ranking
    FROM CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
)
SELECT 
    tc.sr_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_returns,
    tc.total_return_amount,
    COALESCE((SELECT AVG(t.total_return_amount) 
               FROM TopCustomers t 
               WHERE t.cd_gender = tc.cd_gender
               AND t.ranking <= 10), 0) AS average_top_10_return_amount,
    CASE 
        WHEN tc.total_return_amount IS NULL THEN 'No returns'
        ELSE 'Returns made'
    END AS return_status
FROM TopCustomers tc
WHERE tc.ranking <= 5
ORDER BY tc.cd_gender, tc.total_return_amount DESC;