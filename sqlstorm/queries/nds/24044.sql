
WITH RankedItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_manufact,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS web_rank,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY COALESCE(SUM(cs.cs_net_profit), 0) DESC) AS catalog_rank
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name, i.i_manufact
),
FinalResults AS (
    SELECT 
        i.i_item_id AS item_id,
        i.i_product_name,
        i.i_manufact,
        total_web_profit,
        total_catalog_profit,
        web_rank,
        catalog_rank
    FROM 
        RankedItems i
    WHERE 
        web_rank = 1 OR catalog_rank = 1
)
SELECT 
    f.item_id,
    f.i_product_name,
    f.i_manufact,
    f.total_web_profit,
    f.total_catalog_profit,
    CASE 
        WHEN f.total_web_profit > f.total_catalog_profit THEN 'Web Sales Dominant'
        WHEN f.total_catalog_profit > f.total_web_profit THEN 'Catalog Sales Dominant'
        ELSE 'Equal Profit'
    END AS profit_dominance,
    (SELECT COUNT(*) 
     FROM customer_demographics cd
     WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = 'C12345678901234')
     AND cd.cd_marital_status = 'M') AS married_customers_count
FROM 
    FinalResults f
WHERE 
    f.total_web_profit <> f.total_catalog_profit
ORDER BY 
    f.total_web_profit DESC, f.total_catalog_profit DESC
LIMIT 10 OFFSET 10;
