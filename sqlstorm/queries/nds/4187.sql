
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        d.d_date AS sale_date,
        item.i_item_id,
        item.i_item_desc,
        sd.total_quantity,
        sd.total_profit
    FROM 
        sales_data sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    JOIN 
        date_dim d ON sd.rank_profit = 1
    WHERE 
        sd.total_profit > (SELECT AVG(total_profit) FROM sales_data)
)
SELECT 
    ta.sale_date,
    ti.i_item_id,
    ti.i_item_desc,
    COALESCE(TRIM(ti.i_item_desc || ' - Profit: ' || CAST(ta.total_profit AS STRING)), 'No Description') AS item_profit,
    CASE 
        WHEN ta.total_quantity IS NULL THEN 'No Sales'
        ELSE 'Sold ' || ta.total_quantity || ' items'
    END AS sales_info
FROM 
    top_sales ta
LEFT JOIN 
    item ti ON ta.i_item_id = ti.i_item_id
ORDER BY 
    ta.sale_date DESC, 
    ta.total_profit DESC
LIMIT 50;
