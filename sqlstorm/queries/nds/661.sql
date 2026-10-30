
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS rank_by_gender,
        SUM(ss_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 1)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
customer_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
effective_customers AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.total_spent,
        COALESCE(cr.total_returns, 0) AS total_returns,
        TC.total_spent - COALESCE(cr.total_returns, 0) AS net_spent
    FROM top_customers tc
    LEFT JOIN customer_returns cr ON tc.c_customer_sk = cr.sr_customer_sk
    WHERE tc.rank_by_gender <= 5
)
SELECT 
    ec.c_customer_sk,
    ec.c_first_name,
    ec.c_last_name,
    ec.cd_gender,
    ec.total_spent,
    ec.total_returns,
    ec.net_spent
FROM effective_customers ec
WHERE ec.net_spent > 1000
ORDER BY ec.net_spent DESC
LIMIT 10;
