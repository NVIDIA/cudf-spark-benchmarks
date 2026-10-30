
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = 
            (SELECT MAX(ws2.ws_sold_date_sk) 
             FROM web_sales ws2 
             WHERE ws2.ws_item_sk = ws.ws_item_sk)
),
item_locations AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS total_warehouses
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
),
item_promotions AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_promo_sk) AS promo_count
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ranked_sales.sales_rank, 0) AS sales_rank,
    COALESCE(item_locations.total_warehouses, 0) AS total_warehouses,
    COALESCE(item_promotions.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN COALESCE(item_promotions.promo_count, 0) > 5 THEN 'High Promotion'
        WHEN COALESCE(item_promotions.promo_count, 0) BETWEEN 1 AND 5 THEN 'Moderate Promotion'
        ELSE 'No Promotion'
    END AS promotion_status
FROM 
    item i
LEFT JOIN 
    ranked_sales ON i.i_item_sk = ranked_sales.ws_item_sk
LEFT JOIN 
    item_locations ON i.i_item_sk = item_locations.i_item_sk
LEFT JOIN 
    item_promotions ON i.i_item_sk = item_promotions.cs_item_sk
WHERE 
    (i.i_current_price IS NOT NULL AND i.i_current_price > 0) 
    OR 
    (i.i_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0) 
    AND (SELECT AVG(sr_return_amt) FROM store_returns WHERE sr_item_sk = i.i_item_sk) < (SELECT AVG(sr_return_amt) FROM store_returns))
ORDER BY 
    total_net_profit DESC, 
    sales_rank ASC
LIMIT 50;
