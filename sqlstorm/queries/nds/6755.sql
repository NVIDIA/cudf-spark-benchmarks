
WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        w.w_warehouse_id, d.d_year, d.d_month_seq
),
top_warehouses AS (
    SELECT
        w_warehouse_id,
        total_orders,
        total_quantity,
        total_net_profit,
        avg_sales_price,
        RANK() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM
        sales_summary
)
SELECT
    t.w_warehouse_id,
    t.total_orders,
    t.total_quantity,
    t.total_net_profit,
    t.avg_sales_price,
    CASE 
        WHEN t.rank <= 5 THEN 'Top 5%'
        ELSE 'Below Top 5%'
    END AS warehouse_performance
FROM
    top_warehouses t
WHERE
    t.total_net_profit > 10000
ORDER BY
    t.total_net_profit DESC;
