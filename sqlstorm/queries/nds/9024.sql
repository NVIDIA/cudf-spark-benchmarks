
WITH sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        AVG(ws_net_profit) AS average_profit,
        SUM(ws_quantity) AS total_quantity,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ib_income_band_sk
    FROM
        web_sales AS ws
    JOIN
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ws_bill_customer_sk, cd_gender, cd_marital_status, cd_education_status, ib_income_band_sk
), ranked_sales AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        sales_summary
)
SELECT
    rs.ib_income_band_sk,
    COUNT(rs.ws_bill_customer_sk) AS customer_count,
    SUM(rs.total_orders) AS total_orders,
    SUM(rs.total_revenue) AS total_revenue,
    SUM(rs.total_quantity) AS total_quantity,
    AVG(rs.average_profit) AS average_profit_per_customer
FROM
    ranked_sales AS rs
WHERE
    rs.revenue_rank <= 10
GROUP BY
    rs.ib_income_band_sk
ORDER BY
    total_revenue DESC;
