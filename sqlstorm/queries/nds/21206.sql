
WITH CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        dd.d_year,
        dd.d_month_seq,
        dd.d_date,
        ws.ws_net_paid_inc_tax
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year IN (2021, 2022)
        AND cd.cd_gender = 'F'
        AND (cd.cd_credit_rating = 'Good' OR cd.cd_marital_status = 'M')
),
RankedCustomer AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        RANK() OVER (PARTITION BY cd.d_year ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spend_rank
    FROM
        CustomerDetails cd
    JOIN
        web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.d_year
),
TopCustomers AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_spent,
        rc.spend_rank
    FROM
        RankedCustomer rc
    WHERE
        rc.spend_rank <= 10
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
    CASE
        WHEN COALESCE(SUM(sr.sr_return_quantity), 0) > 0 THEN 'Returns Occurred'
        ELSE 'No Returns'
    END AS return_status
FROM
    TopCustomers tc
LEFT JOIN
    store_returns sr ON tc.c_customer_sk = sr.sr_customer_sk
GROUP BY
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent
ORDER BY
    tc.total_spent DESC, tc.c_first_name ASC;
