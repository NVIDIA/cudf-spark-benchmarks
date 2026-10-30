
WITH item_summary AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        SUM(ws.ws_quantity) AS total_sold, 
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND i.i_current_price > 10.00
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
top_items AS (
    SELECT 
        isx.i_item_id, 
        isx.total_sold, 
        isx.total_revenue, 
        isx.order_count,
        ROW_NUMBER() OVER (ORDER BY isx.total_revenue DESC) AS rank
    FROM 
        item_summary isx
)
SELECT 
    ti.i_item_id,
    ti.total_sold,
    ti.total_revenue,
    ti.order_count
FROM 
    top_items ti
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_revenue DESC;
