
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_return_quantity) AS total_returns
    FROM
        store_returns
    WHERE
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
HighReturnCustomers AS (
    SELECT
        cr.sr_customer_sk,
        cr.total_return_amt,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ib_lower_bound,
        cd.ib_upper_bound
    FROM
        CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
    WHERE
        cr.total_return_amt > 1000
),
AggregateReturns AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT src.sr_customer_sk) AS customer_count,
        SUM(src.total_return_amt) AS total_return_amt
    FROM
        HighReturnCustomers src
    GROUP BY
        cd_gender,
        cd_marital_status
),
RankedReturns AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_return_amt DESC) AS rank
    FROM
        AggregateReturns
)
SELECT
    cd_gender,
    cd_marital_status,
    customer_count,
    total_return_amt,
    CASE
        WHEN total_return_amt IS NULL THEN 'No Returns'
        ELSE 'Returns Present'
    END AS return_status,
    CASE 
        WHEN rank <= 5 THEN 'Top Returner'
        ELSE 'Other Returner'
    END AS returner_category
FROM
    RankedReturns
WHERE
    rank <= 10;

