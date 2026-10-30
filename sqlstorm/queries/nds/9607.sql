
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_sales AS (
    SELECT 
        item.i_item_id AS item_id,
        item.i_item_desc AS item_desc,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary AS ss
    JOIN 
        item AS item ON ss.ws_item_sk = item.i_item_sk
)
SELECT 
    ts.item_id,
    ts.item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.total_discount
FROM 
    top_sales AS ts
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC;
