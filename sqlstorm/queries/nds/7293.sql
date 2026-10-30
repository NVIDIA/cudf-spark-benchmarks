
WITH sales_summary AS (
    SELECT
        d.d_year AS year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    GROUP BY
        d.d_year
),
demographics_summary AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid_inc_tax) AS total_revenue
    FROM
        customer_demographics cd
    JOIN
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    s.year,
    s.total_sales,
    s.total_orders,
    d.cd_gender,
    d.cd_marital_status,
    d.total_quantity,
    d.total_revenue
FROM
    sales_summary s
JOIN
    demographics_summary d ON 1=1
ORDER BY
    s.year, d.cd_gender, d.cd_marital_status;
