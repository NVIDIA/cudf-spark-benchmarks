
WITH CustomerReturns AS (
    SELECT 
        COALESCE(wr_returning_customer_sk, sr_customer_sk) AS returning_customer_sk,
        SUM(COALESCE(wr_return_quantity, sr_return_quantity, 0)) AS total_returned,
        COUNT(DISTINCT COALESCE(wr_order_number, sr_ticket_number)) AS unique_returns,
        SUM(COALESCE(wr_return_amt, sr_return_amt, 0)) AS total_return_amt
    FROM 
        web_returns wr
    FULL OUTER JOIN 
        store_returns sr ON wr.wr_item_sk = sr.sr_item_sk AND wr.wr_returned_date_sk = sr.sr_returned_date_sk
    GROUP BY 
        COALESCE(wr_returning_customer_sk, sr_customer_sk)
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), RankedReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returned,
        cr.unique_returns,
        cr.total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_returned DESC) AS rn
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.returning_customer_sk = cd.c_customer_sk
    WHERE 
        (cr.total_returned > 10 OR cr.total_return_amt > 1000)
)
SELECT 
    r.full_name,
    r.cd_gender,
    r.cd_marital_status,
    r.total_returned,
    r.total_return_amt,
    CASE 
        WHEN r.unique_returns > 5 THEN 'High Frequency'
        WHEN r.unique_returns BETWEEN 3 AND 5 THEN 'Medium Frequency'
        ELSE 'Low Frequency' 
    END AS return_frequency
FROM 
    RankedReturns r
WHERE 
    r.rn = 1 
    AND r.cd_gender IS NOT NULL
ORDER BY 
    r.total_return_amt DESC 
LIMIT 50;
