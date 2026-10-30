
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        d_year
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws_item_sk, d_year
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) AS rnk,
        ss.d_year
    FROM 
        sales_summary ss
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.total_discount,
    dd.d_month_seq,
    dd.d_year
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN 
    date_dim dd ON dd.d_year = ti.d_year
WHERE 
    ti.rnk <= 10
ORDER BY 
    dd.d_year, ti.total_sales DESC;
