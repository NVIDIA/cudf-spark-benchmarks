
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS average_net_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq
), 
top_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        sd.average_net_profit,
        RANK() OVER (ORDER BY sd.total_sales_amount DESC) AS sales_rank
    FROM 
        sales_data sd
    WHERE 
        sd.d_year = 2023
)
SELECT 
    ii.i_item_id,
    ii.i_item_desc,
    ti.total_quantity_sold,
    ti.total_sales_amount,
    ti.average_net_profit
FROM 
    top_items ti
JOIN 
    item ii ON ti.ws_item_sk = ii.i_item_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales_amount DESC;
