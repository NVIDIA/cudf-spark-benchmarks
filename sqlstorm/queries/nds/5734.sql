
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
demographic_sales AS (
    SELECT
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.hd_income_band_sk,
        ss.total_orders,
        ss.total_revenue,
        ss.average_profit
    FROM
        customer_info ci
    JOIN
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT
    ds.cd_marital_status,
    ds.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS customer_count,
    SUM(ds.total_revenue) AS total_revenue,
    AVG(ds.average_profit) AS avg_profit
FROM
    demographic_sales ds
JOIN
    income_band ib ON ds.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    ds.cd_marital_status,
    ds.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    ds.cd_marital_status,
    ds.cd_gender;
