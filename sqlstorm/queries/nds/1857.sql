
WITH CustomerReturns AS (
    SELECT
        sr_cdemo_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_cdemo_sk
),
DemographicReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returned,
        cr.total_return_amount,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_return_amount DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_cdemo_sk
),
TopDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(total_return_amount) AS total_return_amount,
        DENSE_RANK() OVER (ORDER BY SUM(total_return_amount) DESC) AS demographic_rank
    FROM DemographicReturns
    GROUP BY cd_gender
),
IncomeThresholds AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE
            WHEN ib_upper_bound IS NULL THEN 'unknown'
            WHEN ib_upper_bound > 100000 THEN 'high'
            WHEN ib_upper_bound BETWEEN 50000 AND 100000 THEN 'medium'
            ELSE 'low'
        END AS income_category
    FROM income_band
)
SELECT 
    td.cd_gender,
    td.customer_count,
    td.total_return_amount,
    it.income_category,
    SUM(td.total_return_amount) OVER (PARTITION BY td.cd_gender, it.income_category ORDER BY td.total_return_amount DESC) AS accumulated_return
FROM TopDemographics td
JOIN IncomeThresholds it ON 
    (td.total_return_amount BETWEEN it.ib_lower_bound AND COALESCE(it.ib_upper_bound, td.total_return_amount));
