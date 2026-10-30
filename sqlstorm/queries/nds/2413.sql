
WITH ranked_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM
        customer c
    INNER JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    INNER JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_customers AS (
    SELECT
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_spent
    FROM
        ranked_sales r
    WHERE
        r.gender_rank <= 5
)
SELECT
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    COALESCE(sr.returned_sales, 0) AS total_returns,
    ROUND((t.total_spent - COALESCE(sr.returned_sales, 0)) / NULLIF(t.total_spent, 0) * 100, 2) AS net_profit_percentage
FROM
    top_customers t
LEFT JOIN (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS returned_sales
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
) sr ON t.c_customer_sk = sr.sr_customer_sk
ORDER BY
    t.total_spent DESC;
