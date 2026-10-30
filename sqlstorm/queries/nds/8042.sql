
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        cr.total_returns,
        cr.total_return_amount,
        cr.return_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        r.r_reason_desc
    FROM
        CustomerReturns cr
    JOIN
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        cr.total_returns > 10
    ORDER BY
        cr.total_return_amount DESC
    LIMIT 10
)
SELECT
    tc.c_customer_id,
    tc.total_returns,
    tc.total_return_amount,
    tc.return_count,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.hd_income_band_sk,
    tc.hd_buy_potential
FROM
    TopCustomers tc
JOIN
    date_dim dd ON dd.d_date_sk = (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_date <= '2002-10-01'
    )
WHERE
    dd.d_month_seq IN (
        SELECT d_month_seq
        FROM date_dim
        WHERE d_year = dd.d_year AND d_dow IN (1, 2, 3, 4, 5)
    )
ORDER BY
    tc.total_return_amount DESC;
