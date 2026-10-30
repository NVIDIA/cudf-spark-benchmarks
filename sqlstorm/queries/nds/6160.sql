
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 
            (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_brand,
        i_category
    FROM 
        item
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        id.i_item_id,
        id.i_brand,
        id.i_category,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_profit,
        RANK() OVER (PARTITION BY id.i_category ORDER BY ss.avg_profit DESC) AS category_rank
    FROM 
        sales_summary ss
    JOIN 
        item_details id ON ss.ws_item_sk = id.i_item_sk
)
SELECT 
    ti.i_item_id,
    ti.i_brand,
    ti.i_category,
    ti.total_quantity,
    ti.total_sales,
    ti.avg_profit
FROM 
    top_items ti
WHERE 
    ti.category_rank <= 5
ORDER BY 
    ti.i_category, ti.avg_profit DESC;
