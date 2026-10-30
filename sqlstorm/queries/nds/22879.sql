
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebReturns AS (
    SELECT
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_quantity) AS total_web_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_web_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        CASE
            WHEN cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd_purchase_estimate < 100 THEN 'LOW'
            WHEN cd_purchase_estimate BETWEEN 100 AND 500 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS purchase_estimate_category
    FROM customer_demographics
),
DateRange AS (
    SELECT
        MIN(d_date) AS start_date,
        MAX(d_date) AS end_date
    FROM date_dim
    WHERE d_current_year = '1'
),
ReturnsSummary AS (
    SELECT
        COALESCE(c.sr_customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.total_returned_quantity, 0) AS total_store_returned_quantity,
        COALESCE(w.total_web_returned_quantity, 0) AS total_web_returned_quantity,
        (COALESCE(c.total_return_amount, 0) + COALESCE(w.total_web_return_amount, 0)) AS total_return_amount,
        d.start_date AS report_start_date,
        d.end_date AS report_end_date
    FROM CustomerReturns c
    FULL OUTER JOIN WebReturns w ON c.sr_customer_sk = w.customer_sk
    CROSS JOIN DateRange d
)
SELECT
    r.customer_sk,
    r.total_store_returned_quantity,
    r.total_web_returned_quantity,
    r.total_return_amount,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    cd.cd_education_status AS education_status,
    r.report_start_date,
    r.report_end_date,
    CASE
        WHEN r.total_return_amount > 1000 THEN 'HIGH VALUE'
        WHEN r.total_return_amount BETWEEN 100 AND 1000 THEN 'MEDIUM VALUE'
        ELSE 'LOW VALUE'
    END AS return_value_category
FROM ReturnsSummary r
LEFT JOIN CustomerDemographics cd ON r.customer_sk = cd.cd_demo_sk
WHERE (r.total_store_returned_quantity > 0 OR r.total_web_returned_quantity > 0)
  AND r.total_return_amount IS NOT NULL
  AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
ORDER BY r.total_return_amount DESC
LIMIT 100;
