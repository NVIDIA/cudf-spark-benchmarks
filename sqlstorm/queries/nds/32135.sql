
WITH  Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458460 AND 2458465  
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
Ranked_Sales AS (
    SELECT 
        ws_item_sk, 
        SUM(total_sales) AS cumulative_sales, 
        SUM(total_profit) AS cumulative_profit 
    FROM 
        Sales_CTE
    WHERE 
        profit_rank <= 5
    GROUP BY 
        ws_item_sk
),
Top_Products AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales.cumulative_sales,
        sales.cumulative_profit
    FROM 
        item
    LEFT JOIN 
        Ranked_Sales sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.cumulative_sales IS NOT NULL
)
SELECT 
    tp.i_item_id,
    tp.i_product_name,
    tp.cumulative_sales,
    tp.cumulative_profit,
    COALESCE(tp.cumulative_profit / NULLIF(tp.cumulative_sales, 0), 0) AS profit_margin
FROM 
    Top_Products tp
ORDER BY 
    tp.cumulative_profit DESC
LIMIT 10;
