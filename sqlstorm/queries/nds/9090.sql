
WITH RankedReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amount,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS return_rank
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
CustomerInsights AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        R.total_returned_quantity,
        R.total_returned_amount
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN RankedReturns R ON c.c_customer_sk = R.wr_returning_customer_sk
    WHERE
        cd.cd_purchase_estimate > 10000
)
SELECT
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_returned_quantity,
    ci.total_returned_amount,
    CASE 
        WHEN ci.total_returned_amount IS NULL THEN 'No Returns'
        WHEN ci.total_returned_amount > 5000 THEN 'High Returner'
        ELSE 'Moderate Returner'
    END AS return_category
FROM
    CustomerInsights ci
ORDER BY
    ci.total_returned_amount DESC
LIMIT 100;
