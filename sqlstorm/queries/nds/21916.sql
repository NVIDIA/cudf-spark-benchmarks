
WITH customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) as dep_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as gender_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year IS NOT NULL
        AND (cd.cd_marital_status IN ('M', 'S') OR (cd.cd_dep_count > 2))
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM
        customer_stats cs
    JOIN
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        cs.c_customer_sk, cs.cd_gender, cs.cd_marital_status
    HAVING
        SUM(ws.ws_ext_sales_price) > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
),
returns_summary AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
        SUM(sr.sr_return_amt) AS total_returns_amount
    FROM
        store_returns sr
    WHERE
        sr.sr_return_quantity > 0
    GROUP BY
        sr.sr_customer_sk
),
detailed_summary AS (
    SELECT
        tc.c_customer_sk,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.total_spent,
        COALESCE(rs.returns_count, 0) AS returns_count,
        COALESCE(rs.total_returns_amount, 0) AS total_returns_amount,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS overall_rank
    FROM
        top_customers tc
    LEFT JOIN
        returns_summary rs ON tc.c_customer_sk = rs.sr_customer_sk
)
SELECT
    d.cd_gender,
    AVG(d.total_spent) AS avg_spent,
    SUM(d.returns_count) AS total_returns,
    SUM(d.total_returns_amount) AS total_returned
FROM
    detailed_summary d
WHERE
    d.overall_rank <= 10
GROUP BY
    d.cd_gender
ORDER BY
    avg_spent DESC
LIMIT 5;
