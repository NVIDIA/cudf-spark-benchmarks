WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2001
    GROUP BY
        w.w_warehouse_id, d.d_year
),
demographic_summary AS (
    SELECT
        cd.cd_gender,
        hd.hd_income_band_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM
        customer_demographics cd
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN
        web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, hd.hd_income_band_sk
)
SELECT
    s.w_warehouse_id,
    s.d_year,
    s.total_sales,
    s.avg_net_profit,
    d.cd_gender,
    d.hd_income_band_sk,
    d.avg_purchase_estimate,
    d.total_items_sold
FROM
    sales_summary s
JOIN
    demographic_summary d ON s.d_year = 2000 
ORDER BY
    s.total_sales DESC, d.avg_purchase_estimate DESC;