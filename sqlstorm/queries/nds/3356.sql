
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned_quantity,
        COALESCE(SUM(sr_return_amt), 0) AS total_returned_amount
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
WebReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amt
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
AggregatedReturns AS (
    SELECT
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt
    FROM
        CustomerReturns cr
    LEFT JOIN WebReturns wr ON cr.c_customer_sk = wr.wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ABS(cd.cd_purchase_estimate) AS adjusted_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM
        customer_demographics cd
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
RankedReturns AS (
    SELECT
        ar.c_customer_sk,
        ar.c_first_name,
        ar.c_last_name,
        ar.total_returned_quantity,
        ar.total_returned_amount,
        ar.total_web_returns,
        ar.total_web_return_amt,
        CASE 
            WHEN cd.cd_demo_sk IS NOT NULL THEN 'Demographic Found'
            ELSE 'No Demographic'
        END AS demographic_status
    FROM
        AggregatedReturns ar
    LEFT JOIN CustomerDemographics cd ON ar.c_customer_sk = cd.cd_demo_sk
    WHERE
        ar.total_returned_quantity > 0 OR ar.total_web_returns > 0
)
SELECT
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_returned_quantity,
    r.total_returned_amount,
    r.total_web_returns,
    r.total_web_return_amt,
    r.demographic_status,
    CASE
        WHEN r.total_returned_amount > 10000 THEN 'High Value Customer'
        WHEN r.total_returned_amount BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM
    RankedReturns r
ORDER BY
    r.total_returned_amount DESC,
    r.c_customer_sk
LIMIT 100
OFFSET 50;
