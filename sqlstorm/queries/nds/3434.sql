
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_value_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        rs.total_quantity,
        rs.total_sales
    FROM 
        item
    JOIN 
        ranked_sales rs ON item.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.rank = 1 AND item.i_current_price IS NOT NULL
),
store_details AS (
    SELECT 
        s_store_name,
        s_city,
        s_state,
        AVG(ss_net_profit) AS average_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s_store_name, s_city, s_state
)
SELECT 
    hvi.i_item_id,
    hvi.i_item_desc,
    hvi.total_sales,
    sd.s_store_name,
    sd.average_profit
FROM 
    high_value_items hvi
LEFT JOIN 
    store_details sd ON hvi.total_sales > sd.average_profit
WHERE 
    hvi.total_quantity > (SELECT AVG(total_quantity) FROM ranked_sales)
ORDER BY 
    hvi.total_sales DESC, sd.average_profit DESC
LIMIT 50;
