
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_qty
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
WebReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(wr_return_quantity) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt,
        AVG(wr_return_quantity) AS avg_web_return_qty
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
AllReturns AS (
    SELECT
        cr.sr_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.avg_return_qty, 0) AS avg_return_qty,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt,
        COALESCE(wr.avg_web_return_qty, 0) AS avg_web_return_qty
    FROM
        CustomerReturns cr
    FULL OUTER JOIN
        WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
IncomeDemographics AS (
    SELECT
        hd.hd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM
        household_demographics hd
    LEFT JOIN
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY
        hd.hd_demo_sk
)
SELECT
    ir.hd_demo_sk,
    ir.customer_count,
    ir.avg_income_band,
    ar.total_returns,
    ar.total_return_amt,
    ar.avg_return_qty,
    ar.total_web_returns,
    ar.total_web_return_amt,
    ar.avg_web_return_qty,
    CASE 
        WHEN ar.total_returns + ar.total_web_returns = 0 THEN 0
        ELSE ROUND((ar.total_return_amt / NULLIF(ar.total_returns + ar.total_web_returns, 0)), 2) 
    END AS avg_return_value
FROM
    IncomeDemographics ir
LEFT JOIN
    AllReturns ar ON ir.hd_demo_sk = ar.sr_customer_sk
WHERE
    ir.customer_count > 10
ORDER BY
    ir.customer_count DESC,
    avg_return_value DESC;
