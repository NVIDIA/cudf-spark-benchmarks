
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND i.i_current_price > 20.00
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity, 
        sd.total_sales, 
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    ts.total_quantity, 
    ts.total_sales, 
    ts.total_profit
FROM 
    top_sales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC;
