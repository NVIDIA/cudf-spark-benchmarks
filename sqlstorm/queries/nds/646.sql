
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws1.ws_sold_date_sk) FROM web_sales ws1)
    GROUP BY 
        w.w_warehouse_id, s.s_store_name
),
FilteredSales AS (
    SELECT 
        *,
        CASE 
            WHEN total_quantity > 100 THEN 'High' 
            WHEN total_quantity BETWEEN 50 AND 100 THEN 'Medium' 
            ELSE 'Low' 
        END AS quantity_category
    FROM 
        SalesData 
    WHERE 
        rank <= 5
),
Promotions AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_usage
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    f.w_warehouse_id, 
    f.s_store_name,
    f.total_quantity,
    f.total_profit,
    f.quantity_category,
    COALESCE(p.promo_usage, 0) AS promo_usage
FROM 
    FilteredSales f
LEFT JOIN 
    Promotions p ON f.total_profit >= 0 
ORDER BY 
    f.total_profit DESC;
