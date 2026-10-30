WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_moy IN (6, 7, 8) 
    GROUP BY
        w.w_warehouse_id
),
top_sales AS (
    SELECT
        w_warehouse_id,
        total_quantity_sold,
        total_sales,
        avg_net_profit,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    ts.w_warehouse_id,
    ts.total_quantity_sold,
    ts.total_sales,
    ts.avg_net_profit,
    ts.total_orders
FROM
    top_sales ts
WHERE
    ts.sales_rank <= 10
ORDER BY
    ts.total_sales DESC;