
WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity_sold,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(COALESCE(ws.ws_net_profit, 0)) AS average_profit
    FROM
        warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        w.w_warehouse_id
),
demographic_summary AS (
    SELECT
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_marital_status
)
SELECT
    ss.w_warehouse_id,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.total_orders,
    ss.average_profit,
    ds.cd_marital_status,
    ds.customer_count,
    ds.avg_purchase_estimate
FROM
    sales_summary ss
JOIN demographic_summary ds ON ss.total_orders > 10
ORDER BY 
    ss.total_sales_amount DESC, 
    ds.customer_count DESC
LIMIT 100;
