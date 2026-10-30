
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'male'
            ELSE 'female'
        END AS gender_normalized
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RankedReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_value,
        cr.avg_return_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_return_value DESC) AS return_rank
    FROM CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
)
SELECT 
    r.sr_customer_sk,
    cr.total_returns,
    cr.total_return_value,
    cr.avg_return_quantity,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    r.return_rank,
    CASE
        WHEN r.return_rank = 1 THEN 'Top Returner'
        WHEN cr.total_return_value IS NULL THEN 'No Returns'
        ELSE 'Regular'
    END AS return_status
FROM RankedReturns r
JOIN CustomerReturns cr ON r.sr_customer_sk = cr.sr_customer_sk 
LEFT JOIN CustomerDemographics cd ON r.sr_customer_sk = cd.c_customer_sk
WHERE (cd.cd_marital_status IS NULL OR cd.cd_marital_status <> 'D')
AND cr.total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
ORDER BY cr.total_return_value DESC, cr.total_returns ASC
LIMIT 50;
