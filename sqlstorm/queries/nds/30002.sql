
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit 
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_net_profit) AS total_profit 
    FROM 
        catalog_sales 
    GROUP BY 
        cs_item_sk
),
Ranked_Sales AS (
    SELECT 
        i.i_item_id,
        COALESCE(ws.total_quantity, 0) AS web_quantity,
        COALESCE(cs.total_quantity, 0) AS catalog_quantity,
        COALESCE(ws.total_profit, 0) AS web_profit,
        COALESCE(cs.total_profit, 0) AS catalog_profit,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ws.total_profit, 0) DESC, COALESCE(cs.total_profit, 0) DESC) AS rank
    FROM 
        item i
    LEFT JOIN 
        (SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_profit) AS total_profit 
         FROM web_sales 
         GROUP BY ws_item_sk) ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        (SELECT cs_item_sk, SUM(cs_quantity) AS total_quantity, SUM(cs_net_profit) AS total_profit 
         FROM catalog_sales 
         GROUP BY cs_item_sk) cs ON i.i_item_sk = cs.cs_item_sk
)
SELECT 
    r.i_item_id,
    r.web_quantity,
    r.catalog_quantity,
    r.web_profit,
    r.catalog_profit,
    CASE 
        WHEN r.web_quantity > r.catalog_quantity THEN 'Web Sales Dominant'
        WHEN r.catalog_quantity > r.web_quantity THEN 'Catalog Sales Dominant'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM 
    Ranked_Sales r
WHERE 
    r.rank <= 10
ORDER BY 
    r.web_profit DESC NULLS LAST, 
    r.catalog_profit DESC NULLS LAST;

