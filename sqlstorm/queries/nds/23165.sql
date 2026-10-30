
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory,
        MAX(inv_date_sk) AS latest_inventory_date
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
EnhancedStats AS (
    SELECT 
        r.ws_item_sk,
        r.total_sold,
        r.total_profit,
        COALESCE(i.total_inventory, 0) AS total_inventory,
        CASE 
            WHEN r.total_profit < 0 THEN 'Loss'
            WHEN r.total_profit = 0 THEN 'Break-even'
            ELSE 'Profit'
        END AS profit_status,
        CASE 
            WHEN r.total_sold > 100 THEN 'High Demand' 
            WHEN r.total_sold BETWEEN 50 AND 100 THEN 'Moderate Demand'
            ELSE 'Low Demand'
        END AS demand_category
    FROM 
        RecursiveSales r
    LEFT JOIN 
        InventoryStatus i ON r.ws_item_sk = i.inv_item_sk
    WHERE 
        r.rank = 1
)
SELECT 
    e.ws_item_sk,
    e.total_sold,
    e.total_profit,
    e.total_inventory,
    e.profit_status,
    e.demand_category,
    COALESCE(pc.promotion_count, 0) AS active_promotions
FROM 
    EnhancedStats e
LEFT JOIN (
    SELECT 
        p.p_item_sk,
        COUNT(p.p_promo_sk) AS promotion_count
    FROM 
        promotion p
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
        AND p.p_end_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
    GROUP BY 
        p.p_item_sk
) pc ON e.ws_item_sk = pc.p_item_sk
WHERE 
    (e.total_inventory IS NOT NULL OR e.total_sold > 50)
ORDER BY 
    e.total_profit DESC, e.total_sold DESC;
