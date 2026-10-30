
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(ii.inv_quantity_on_hand), 0) AS quantity_on_hand
    FROM 
        item i
    LEFT JOIN 
        inventory ii ON i.i_item_sk = ii.inv_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.avg_sales_price,
    id.quantity_on_hand,
    (CASE 
        WHEN id.quantity_on_hand < ts.total_quantity THEN 'Low Stock' 
        ELSE 'Sufficient Stock' 
     END) AS stock_status
FROM 
    top_sales ts
JOIN 
    item_details id ON ts.ws_item_sk = id.i_item_sk
ORDER BY 
    ts.total_sales DESC;
