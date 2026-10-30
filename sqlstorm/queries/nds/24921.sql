
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
filtered_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity_sold,
        rs.total_net_profit,
        (CASE 
            WHEN rs.total_net_profit IS NULL THEN 'No Profit'
            WHEN rs.total_quantity_sold = 0 THEN 'No Sales'
            ELSE 'Active'
        END) AS sales_status,
        (SELECT 
            AVG(ss_ext_discount_amt) 
         FROM 
            store_sales 
         WHERE 
            ss_item_sk = rs.ws_item_sk) AS avg_discount
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank_profit <= 10
)
SELECT 
    fs.ws_item_sk,
    fs.total_quantity_sold,
    fs.total_net_profit,
    fs.sales_status,
    COALESCE(fs.avg_discount, 0) AS avg_discount,
    CASE 
        WHEN fs.total_net_profit > 1000 THEN 'High Profit'
        WHEN fs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    filtered_sales fs
LEFT JOIN 
    item i ON fs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    promotion p ON p.p_item_sk = fs.ws_item_sk
WHERE 
    (i.i_color IS NULL OR i.i_color <> 'Red')
    AND fs.total_quantity_sold >= (SELECT AVG(total_quantity_sold) FROM filtered_sales)
    OR fs.sales_status = 'No Profit'
ORDER BY 
    fs.sales_status DESC, 
    fs.total_net_profit DESC;
