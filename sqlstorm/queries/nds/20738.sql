
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_item_sk) AS web_total_returns,
        SUM(wr_return_amt_inc_tax) AS web_total_return_amount,
        SUM(wr_return_quantity) AS total_web_return_quantity
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
AggregatedReturns AS (
    SELECT 
        COALESCE(c.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(total_returns, 0) + COALESCE(web_total_returns, 0) AS aggregated_returns,
        COALESCE(total_return_amount, 0) + COALESCE(web_total_return_amount, 0) AS aggregated_return_amount
    FROM CustomerReturns c
    FULL OUTER JOIN WebReturns wr ON c.sr_customer_sk = wr.wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        h.hd_buy_potential
    FROM customer_demographics cd
    LEFT JOIN household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    LEFT JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
),
ReturnSummary AS (
    SELECT 
        cr.customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ib_lower_bound,
        cd.ib_upper_bound,
        COUNT(cr.aggregated_returns) AS total_customers,
        SUM(cr.aggregated_return_amount) AS total_return_amount
    FROM AggregatedReturns cr
    JOIN CustomerDemographics cd ON cr.customer_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status IS NOT NULL
    GROUP BY cr.customer_sk, cd.cd_gender, cd.cd_marital_status, cd.ib_lower_bound, cd.ib_upper_bound
)
SELECT 
    rs.customer_sk,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.ib_lower_bound,
    rs.ib_upper_bound,
    rs.total_customers,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    RANK() OVER (PARTITION BY rs.cd_gender ORDER BY rs.total_return_amount DESC) AS gender_rank
FROM ReturnSummary rs
WHERE rs.total_return_amount IS NOT NULL AND rs.total_customers >= 0
ORDER BY rs.total_return_amount DESC NULLS LAST;
