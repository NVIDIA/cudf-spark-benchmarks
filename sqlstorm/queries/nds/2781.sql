
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2002-10-01')
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_order_number,
        sd.ws_sales_price,
        sd.ws_net_profit
    FROM 
        sales_data sd
    WHERE 
        sd.rn <= 10
)
SELECT 
    ta.i_item_id, 
    ta.i_product_name, 
    COALESCE(ts.ws_sales_price, 0) AS top_sales_price, 
    COALESCE(ts.ws_net_profit, 0) AS top_net_profit,
    tc.d_day_name,
    tc.d_date
FROM 
    item ta
LEFT JOIN 
    top_sales ts ON ta.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    date_dim tc ON tc.d_date_sk = (SELECT MAX(dd.d_date_sk) FROM date_dim dd WHERE dd.d_date = '2002-10-01')
WHERE 
    ta.i_category_id IN (
        SELECT DISTINCT 
            i_category_id 
        FROM 
            item
        WHERE 
            i_current_price > (SELECT AVG(i_current_price) FROM item)
    )
ORDER BY 
    top_sales_price DESC, 
    top_net_profit DESC;
