
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS warehouse_profit,
        COUNT(DISTINCT ws.ws_order_number) AS warehouse_orders
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
PromotionStats AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders,
        SUM(ws.ws_net_profit) AS promo_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_profit,
    ws.warehouse_profit,
    ws.warehouse_orders,
    ps.promo_orders,
    ps.promo_profit
FROM 
    CustomerStats cs
JOIN 
    WarehouseStats ws ON cs.total_orders > 0
JOIN 
    PromotionStats ps ON cs.total_orders > 0
ORDER BY 
    cs.total_profit DESC, cs.total_orders DESC
LIMIT 100;
