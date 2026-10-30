
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_item_sk
), Item_Details AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        i.i_current_price,
        COALESCE(NULLIF(SUM(ss.ss_quantity), 0), 1) AS total_store_sales
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_brand, i.i_current_price
), Top_Sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        s.total_net_profit,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price,
        ROW_NUMBER() OVER (ORDER BY s.total_net_profit DESC) AS item_rank
    FROM Sales_CTE s
    JOIN Item_Details i ON s.ws_item_sk = i.i_item_sk
    WHERE s.rank <= 10
)
SELECT 
    ts.item_rank, 
    ts.i_item_desc, 
    ts.i_brand, 
    ts.i_current_price,
    ts.total_sales,
    ts.total_net_profit,
    CASE 
        WHEN ts.total_net_profit > 1000 THEN 'High Profit'
        WHEN ts.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    COALESCE((SELECT 
                AVG(total_net_profit) 
              FROM Top_Sales 
              WHERE i_brand = ts.i_brand), 0) AS avg_brand_profit
FROM Top_Sales ts
ORDER BY ts.item_rank;
