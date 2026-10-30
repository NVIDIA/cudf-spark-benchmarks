
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_return_quantity) AS return_count,
        SUM(sr.sr_return_quantity) AS total_returned,
        AVG(sr.sr_return_quantity) AS avg_returned
    FROM
        customer AS c
    LEFT JOIN
        RankedReturns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk
),
CustomerIncome AS (
    SELECT
        c.c_customer_sk,
        CASE
            WHEN h.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low'
            WHEN h.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Medium'
            ELSE 'High'
        END AS income_band,
        AVG(s.ws_net_profit) AS avg_profit
    FROM
        customer AS c
    JOIN
        household_demographics AS h ON c.c_current_hdemo_sk = h.hd_demo_sk
    LEFT JOIN
        web_sales AS s ON c.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, h.hd_income_band_sk
)
SELECT
    c.c_customer_sk AS customer_id,
    cs.return_count,
    cs.total_returned,
    cs.avg_returned,
    ci.income_band,
    ci.avg_profit
FROM
    customer AS c
JOIN
    CustomerStats AS cs ON c.c_customer_sk = cs.c_customer_sk
JOIN
    CustomerIncome AS ci ON c.c_customer_sk = ci.c_customer_sk
WHERE
    cs.return_count > 0
    AND ci.avg_profit IS NOT NULL
ORDER BY
    cs.total_returned DESC,
    ci.avg_profit DESC
LIMIT 100 OFFSET 0;
