WITH recent_sales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2001
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_item_desc, 
        CASE 
            WHEN i.i_current_price IS NULL THEN 0 
            ELSE i.i_current_price 
        END AS price
    FROM item i
),
top_items AS (
    SELECT 
        rs.ws_item_sk, 
        id.i_item_id, 
        id.i_item_desc, 
        rs.total_quantity_sold, 
        rs.total_revenue, 
        ROW_NUMBER() OVER (ORDER BY rs.total_revenue DESC) AS item_rank
    FROM recent_sales rs
    INNER JOIN item_details id ON rs.ws_item_sk = id.i_item_sk
)
SELECT 
    ti.i_item_id, 
    ti.i_item_desc, 
    ti.total_quantity_sold, 
    ti.total_revenue, 
    CASE 
        WHEN ti.total_revenue > 10000 THEN 'High Performer'
        ELSE 'Regular Performer' 
    END AS performance_category
FROM top_items ti
WHERE ti.item_rank <= 10 
ORDER BY ti.total_revenue DESC;