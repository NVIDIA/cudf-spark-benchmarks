
WITH recent_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (
        SELECT MAX(d_date_sk) - 30 
        FROM date_dim 
        WHERE d_current_month = 'Y'
    ) AND (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_current_month = 'Y'
    )
    GROUP BY ss_store_sk
),
average_profit AS (
    SELECT 
        AVG(total_net_profit) AS avg_net_profit 
    FROM recent_sales
),
promotional_sales AS (
    SELECT 
        cs_promo_sk,
        SUM(cs_net_profit) AS promo_net_profit
    FROM catalog_sales
    GROUP BY cs_promo_sk
),
inventory_status AS (
    SELECT 
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT 
    w.w_warehouse_name,
    inv.total_quantity,
    COALESCE(s.total_net_profit, 0) AS store_net_profit,
    CASE 
        WHEN s.total_net_profit > a.avg_net_profit THEN 'Above Average'
        WHEN s.total_net_profit = a.avg_net_profit THEN 'Average'
        ELSE 'Below Average'
    END AS profit_comparison,
    p.promo_net_profit
FROM warehouse w
LEFT JOIN (
    SELECT 
        r.ss_store_sk,
        SUM(r.ss_net_profit) AS total_net_profit
    FROM store_sales r
    JOIN recent_sales s ON r.ss_store_sk = s.ss_store_sk
    GROUP BY r.ss_store_sk
) s ON w.w_warehouse_sk = s.ss_store_sk
JOIN inventory_status inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
CROSS JOIN average_profit a
LEFT JOIN promotional_sales p ON p.cs_promo_sk = (
    SELECT cs_promo_sk 
    FROM catalog_sales 
    GROUP BY cs_promo_sk
    ORDER BY SUM(cs_net_profit) DESC
    LIMIT 1
)
WHERE inv.total_quantity > 0 
AND (s.total_net_profit IS NULL OR s.total_net_profit <> 0)
ORDER BY w.w_warehouse_name;
