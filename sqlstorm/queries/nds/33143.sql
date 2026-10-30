
WITH  item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM catalog_sales
    GROUP BY cs_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(w.total_quantity, 0) AS total_web_quantity,
    COALESCE(c.total_quantity, 0) AS total_catalog_quantity,
    COALESCE(w.total_profit, 0) AS total_web_profit,
    COALESCE(c.total_profit, 0) AS total_catalog_profit,
    (COALESCE(w.total_profit, 0) + COALESCE(c.total_profit, 0)) AS overall_profit
FROM 
    item i
LEFT JOIN (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_item_sk
) w ON i.i_item_sk = w.ws_item_sk
LEFT JOIN (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    GROUP BY cs_item_sk
) c ON i.i_item_sk = c.cs_item_sk
WHERE 
    (COALESCE(w.total_quantity, 0) > 0 OR COALESCE(c.total_quantity, 0) > 0)
    AND i.i_current_price IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
        AND p.p_discount_active = 'Y'
    )
ORDER BY overall_profit DESC
LIMIT 10;
