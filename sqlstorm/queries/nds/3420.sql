
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_profit <= 10
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_profit,
    COALESCE(t.i_item_desc, 'Unknown Item') AS item_description,
    t.i_brand,
    t.i_category,
    COUNT(DISTINCT w.wp_web_page_sk) AS page_count
FROM 
    TopSales t
LEFT JOIN 
    web_page w ON t.ws_item_sk = w.wp_web_page_sk
GROUP BY 
    t.ws_item_sk, t.total_quantity, t.total_profit, t.i_item_desc, t.i_brand, t.i_category
HAVING 
    SUM(t.total_profit) > 1000
ORDER BY 
    t.total_profit DESC
LIMIT 20;
