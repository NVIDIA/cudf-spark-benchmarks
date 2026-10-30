
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_item_sk) AS unique_items_returned
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
TopCustomers AS (
    SELECT
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        ROW_NUMBER() OVER (ORDER BY cr.total_returned_amount DESC) AS rank
    FROM
        CustomerReturns cr
),
ReturnReasons AS (
    SELECT
        sr_reason_sk,
        r.r_reason_desc,
        COUNT(*) AS reason_count
    FROM
        store_returns sr
    LEFT JOIN
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY
        sr_reason_sk, r.r_reason_desc
    HAVING
        COUNT(*) > 5
),
FilteredReasons AS (
    SELECT
        rr.r_reason_desc,
        rr.reason_count,
        CASE 
            WHEN rr.reason_count BETWEEN 5 AND 10 THEN 'Moderate'
            WHEN rr.reason_count BETWEEN 11 AND 20 THEN 'High'
            ELSE 'Very High'
        END AS reason_category
    FROM
        ReturnReasons rr
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        CASE 
            WHEN cd.cd_dep_count IS NULL OR cd.cd_dep_count = 0 THEN 'No Dependents'
            ELSE 'Has Dependents'
        END AS dependents_status
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    tc.sr_customer_sk,
    cd.cd_gender,
    cd.dependents_status,
    tc.total_returns,
    tc.total_returned_quantity,
    tc.total_returned_amount,
    fr.r_reason_desc,
    SUM(fr.reason_count) OVER () AS total_reasons_count
FROM
    TopCustomers tc
JOIN
    CustomerDemographics cd ON tc.sr_customer_sk = cd.c_customer_sk
LEFT JOIN
    FilteredReasons fr ON tc.total_returns > 5
WHERE
    cd.cd_credit_rating IS NOT NULL
    AND tc.rank <= 10
ORDER BY
    tc.total_returned_amount DESC,
    cd.cd_gender ASC,
    fr.reason_count DESC
LIMIT 5;
