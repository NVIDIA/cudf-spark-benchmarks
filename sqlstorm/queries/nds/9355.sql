
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        ss.total_tax
    FROM 
        sales_summary ss
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.total_discount,
    ti.total_tax
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
ORDER BY 
    ti.total_sales DESC;
