
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(dt.d_date) AS latest_sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dt ON ws.ws_sold_date_sk = dt.d_date_sk
    GROUP BY 
        ws.ws_item_sk
),
top_selling_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_net_profit,
        ss.total_orders,
        ss.latest_sale_date,
        ROW_NUMBER() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM 
        sales_summary ss
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity_sold,
    tsi.total_net_profit,
    tsi.total_orders,
    tsi.latest_sale_date
FROM 
    top_selling_items tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
WHERE 
    tsi.rank <= 10
ORDER BY 
    tsi.total_net_profit DESC;
