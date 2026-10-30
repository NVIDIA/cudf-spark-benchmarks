
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, i.i_item_id, i.i_item_desc
),
top_items AS (
    SELECT 
        year,
        month_seq,
        item_id,
        item_desc,
        total_quantity,
        total_sales,
        avg_net_profit,
        RANK() OVER (PARTITION BY year, month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        (SELECT 
            d_year AS year, 
            d_month_seq AS month_seq, 
            i_item_id AS item_id, 
            i_item_desc AS item_desc, 
            total_quantity, 
            total_sales, 
            avg_net_profit 
         FROM sales_summary) AS item_sales
)
SELECT 
    ti.year,
    ti.month_seq,
    ti.item_id,
    ti.item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.avg_net_profit
FROM 
    top_items ti
WHERE 
    ti.sales_rank <= 5
ORDER BY 
    ti.year, ti.month_seq, ti.total_sales DESC;
