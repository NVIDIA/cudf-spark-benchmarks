
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk AS date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = (SELECT MAX(d_year) FROM date_dim))
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
filtered_summary AS (
    SELECT 
        date_sk,
        ws_item_sk,
        total_profit,
        total_sales,
        sales_rank
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 5
),
top_items AS (
    SELECT 
        fs.date_sk,
        fs.ws_item_sk,
        fs.total_profit,
        fs.total_sales,
        i.i_item_desc,
        ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('month', d.d_date) ORDER BY fs.total_profit DESC) AS monthly_rank
    FROM 
        filtered_summary fs
    JOIN 
        item i ON fs.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON fs.date_sk = d.d_date_sk
)
SELECT 
    ti.date_sk,
    d.d_date AS sale_date,
    ti.ws_item_sk,
    ti.i_item_desc,
    ti.total_profit,
    ti.total_sales,
    ti.monthly_rank,
    COALESCE(sm.sm_type, 'Unknown') AS shipping_method,
    CASE 
        WHEN ti.total_profit > 1000 THEN 'High Profit'
        WHEN ti.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM 
    top_items ti
LEFT JOIN 
    ship_mode sm ON ti.ws_item_sk = sm.sm_ship_mode_sk
JOIN 
    date_dim d ON ti.date_sk = d.d_date_sk
WHERE 
    ti.monthly_rank <= 3
ORDER BY 
    ti.date_sk, ti.total_profit DESC;
