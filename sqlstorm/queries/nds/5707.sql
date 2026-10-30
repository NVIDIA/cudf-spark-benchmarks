
WITH sales_data AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_sold_date_sk = sr.sr_returned_date_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
top_products AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_returns,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    p.i_item_id,
    p.i_item_desc,
    tp.total_quantity,
    tp.total_sales,
    tp.total_returns,
    tp.sales_rank
FROM 
    top_products tp
JOIN 
    item p ON tp.ws_item_sk = p.i_item_sk
WHERE 
    tp.sales_rank <= 10
ORDER BY 
    tp.total_sales DESC;
