
WITH CustomerSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_net_paid, 0)) DESC) AS rn
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        cd.cd_marital_status = 'M' AND
        cd.cd_gender = 'F'
    GROUP BY
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
),
HighSpenders AS (
    SELECT *
    FROM CustomerSummary
    WHERE total_spent > 1000
),
ReturnStats AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
FinalReport AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.return_count, 0) AS return_count,
        CASE
            WHEN cs.total_spent >= 1000 THEN 'High Value'
            WHEN cs.total_spent < 1000 AND cs.total_spent > 500 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM
        HighSpenders cs
    LEFT JOIN ReturnStats rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_spent,
    f.total_returns,
    f.return_count,
    f.customer_value_segment
FROM
    FinalReport f
ORDER BY
    f.total_spent DESC, f.return_count DESC;
