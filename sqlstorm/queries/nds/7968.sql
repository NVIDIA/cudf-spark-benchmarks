
WITH sales_summary AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2019 AND 2021
    GROUP BY
        d.d_year, i.i_category
),
top_sales AS (
    SELECT 
        y.d_year, 
        y.i_category, 
        y.total_quantity, 
        y.total_sales, 
        y.avg_net_paid, 
        y.total_orders,
        RANK() OVER (PARTITION BY y.d_year ORDER BY y.total_sales DESC) AS rank
    FROM 
        sales_summary y
)
SELECT 
    t.d_year,
    t.i_category,
    t.total_quantity,
    t.total_sales,
    t.avg_net_paid,
    t.total_orders
FROM 
    top_sales t
WHERE 
    t.rank <= 5
ORDER BY 
    t.d_year, t.total_sales DESC;
