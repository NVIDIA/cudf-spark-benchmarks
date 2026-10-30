
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk AS sold_date,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
top_items AS (
    SELECT 
        sold_date,
        ws_item_sk,
        RANK() OVER (PARTITION BY sold_date ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    dd.d_date AS sales_date,
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.total_discount,
    ts.avg_net_profit
FROM 
    top_items ti
JOIN 
    sales_summary ts ON ti.sold_date = ts.sold_date AND ti.ws_item_sk = ts.ws_item_sk
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
JOIN 
    date_dim dd ON ti.sold_date = dd.d_date_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    sales_date, total_sales DESC;
