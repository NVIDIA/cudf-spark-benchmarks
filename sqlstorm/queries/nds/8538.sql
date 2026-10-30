
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value,
        AVG(ws.ws_net_profit) AS average_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        dd.d_year
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY ws.ws_item_sk, dd.d_year
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_sales_value,
        ss.average_net_profit,
        ss.total_orders,
        RANK() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales_value DESC) AS sales_rank,
        ss.d_year
    FROM sales_summary ss
)
SELECT 
    t.ws_item_sk,
    t.total_quantity_sold,
    t.total_sales_value,
    t.average_net_profit,
    t.total_orders,
    d.d_year
FROM top_items t
JOIN date_dim d ON t.d_year = d.d_year
WHERE t.sales_rank <= 10
ORDER BY d.d_year, t.sales_rank;
