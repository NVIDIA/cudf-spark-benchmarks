
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
PotentialProfits AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS catalog_net_profit,
        CASE 
            WHEN SUM(cs_net_profit) > 0 THEN 'Profitable'
            WHEN SUM(cs_net_profit) < 0 THEN 'Loss'
            ELSE 'Break Even'
        END AS profit_status
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
FinalSales AS (
    SELECT 
        i.i_item_id,
        COALESCE(RS.total_quantity, 0) AS total_web_quantity,
        COALESCE(RS.total_net_profit, 0) AS total_web_profit,
        COALESCE(PS.catalog_net_profit, 0) AS total_catalog_profit,
        PS.profit_status,
        CASE 
            WHEN COALESCE(RS.total_net_profit, 0) > COALESCE(PS.catalog_net_profit, 0) THEN 'Web Dominant'
            WHEN COALESCE(RS.total_net_profit, 0) < COALESCE(PS.catalog_net_profit, 0) THEN 'Catalog Dominant'
            ELSE 'Equal'
        END AS dominance_status
    FROM 
        item AS i
    LEFT JOIN 
        RankedSales AS RS ON i.i_item_sk = RS.ws_item_sk
    LEFT JOIN 
        PotentialProfits AS PS ON i.i_item_sk = PS.cs_item_sk
)
SELECT 
    f.i_item_id,
    f.total_web_quantity,
    f.total_web_profit,
    f.total_catalog_profit,
    f.profit_status,
    f.dominance_status
FROM 
    FinalSales AS f
WHERE 
    f.profit_status = 'Profitable' 
    OR (f.total_web_profit IS NULL AND f.total_catalog_profit > 0)
ORDER BY 
    f.total_web_profit DESC NULLS LAST,
    f.total_catalog_profit DESC NULLS LAST;
