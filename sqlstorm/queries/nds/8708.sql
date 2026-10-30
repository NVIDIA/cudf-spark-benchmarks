
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_units_sold
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
),
demographics_summary AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
),
combined_summary AS (
    SELECT
        ss.d_year,
        ss.d_month_seq,
        ds.cd_gender,
        ds.total_customers,
        ds.total_purchase_estimate,
        ss.total_sales,
        ss.total_orders,
        ss.total_units_sold,
        ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) AS rn
    FROM
        sales_summary ss
    JOIN
        demographics_summary ds ON ds.total_customers > 0
)
SELECT
    cs.d_year,
    cs.d_month_seq,
    cs.cd_gender,
    cs.total_customers,
    cs.total_purchase_estimate,
    cs.total_sales,
    cs.total_orders,
    cs.total_units_sold
FROM
    combined_summary cs
WHERE
    cs.rn <= 5
ORDER BY
    cs.d_year, cs.total_sales DESC;
