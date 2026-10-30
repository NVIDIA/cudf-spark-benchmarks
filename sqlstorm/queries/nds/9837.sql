
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        d_year,
        d_month_seq
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        ws_item_sk, d_year, d_month_seq
),
item_details AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_brand,
        i_category,
        i_size,
        i_color
    FROM 
        item
),
combined_data AS (
    SELECT 
        sd.ws_item_sk,
        id.i_product_name,
        id.i_brand,
        id.i_category,
        id.i_size,
        id.i_color,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        ROW_NUMBER() OVER(PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_profit DESC) AS profit_rank,
        sd.d_year,
        sd.d_month_seq
    FROM 
        sales_data sd
    JOIN 
        item_details id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    cd.year,
    cd.month,
    COUNT(*) AS top_products_count,
    AVG(c.total_profit) AS avg_profit
FROM 
    (SELECT DISTINCT d_year AS year, d_month_seq AS month FROM sales_data) cd
JOIN 
    combined_data c ON cd.year = c.d_year AND cd.month = c.d_month_seq
WHERE 
    c.profit_rank <= 10
GROUP BY 
    cd.year, cd.month
ORDER BY 
    cd.year, cd.month;
