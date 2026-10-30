
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS net_revenue
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM
        web_returns
    GROUP BY
        wr_refunded_customer_sk
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_sales,
    ss.order_count,
    rs.total_returns,
    rs.return_count,
    COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0) AS net_sales,
    CASE
        WHEN COALESCE(ss.order_count, 0) > 0 THEN (COALESCE(rs.return_count, 0) * 1.0 / ss.order_count) * 100
        ELSE 0
    END AS return_rate
FROM
    customer_info ci
LEFT JOIN
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN
    returns_summary rs ON ci.c_customer_sk = rs.wr_refunded_customer_sk
WHERE
    ci.customer_rank = 1
    AND (ss.total_sales > 1000 OR rs.return_count > 0)
ORDER BY
    net_sales DESC
LIMIT 100;
