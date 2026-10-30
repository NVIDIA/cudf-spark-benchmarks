
WITH SalesAggregates AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_net_paid) AS total_revenue 
    FROM 
        web_sales 
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
TopItems AS (
    SELECT 
        sa.ws_item_sk, 
        i.i_product_name, 
        sa.total_quantity_sold, 
        sa.total_revenue, 
        RANK() OVER (ORDER BY sa.total_quantity_sold DESC) AS rank_by_quantity,
        RANK() OVER (ORDER BY sa.total_revenue DESC) AS rank_by_revenue 
    FROM 
        SalesAggregates sa 
    JOIN 
        item i ON sa.ws_item_sk = i.i_item_sk
),
DailySales AS (
    SELECT 
        d.d_date, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_daily_revenue 
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    GROUP BY 
        d.d_date
)
SELECT 
    di.d_date, 
    di.total_orders, 
    di.total_daily_revenue, 
    ti.i_product_name, 
    ti.total_quantity_sold, 
    ti.total_revenue 
FROM 
    DailySales di 
JOIN 
    TopItems ti ON ti.rank_by_quantity <= 10 
ORDER BY 
    di.d_date DESC, 
    ti.total_revenue DESC 
LIMIT 100;
