
WITH RankedReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        DENSE_RANK() OVER (PARTITION BY sr_customer_sk ORDER BY COUNT(sr_ticket_number) DESC) AS return_rank
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        rd.total_returns,
        rd.total_return_amount
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        RankedReturns rd ON c.c_customer_sk = rd.sr_customer_sk
    WHERE
        cd.cd_gender = 'F' AND
        (cd.cd_purchase_estimate IS NOT NULL OR rd.total_returns > 0)
),
HighValueReturns AS (
    SELECT
        cd.c_first_name,
        cd.c_last_name,
        cd.total_return_amount,
        COALESCE(NULLIF(cd.total_return_amount, 0), 1) AS safe_divisor,
        ROUND(cd.total_return_amount / COALESCE(NULLIF(cd.total_return_amount, 0), 1), 2) AS average_return
    FROM
        CustomerDetails cd
    WHERE
        cd.total_return_amount > 100
)
SELECT
    *,
    CASE 
        WHEN average_return > 100 THEN 'High Return'
        WHEN average_return BETWEEN 50 AND 100 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category
FROM
    HighValueReturns
ORDER BY
    average_return DESC;

