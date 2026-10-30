
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_ship_date_sk,
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_revenue
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.revenue_rank <= 5
)
SELECT 
    dd.d_date AS sales_date,
    COUNT(DISTINCT ts.i_item_id) AS top_items_count,
    SUM(ts.total_revenue) AS total_revenue
FROM 
    TopSales ts
JOIN 
    date_dim dd ON ts.ws_ship_date_sk = dd.d_date_sk
GROUP BY 
    dd.d_date
ORDER BY 
    dd.d_date ASC;
