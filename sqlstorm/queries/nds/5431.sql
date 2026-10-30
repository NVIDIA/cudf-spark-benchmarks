
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
WarehouseInventory AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM 
        warehouse AS w
    JOIN 
        inventory AS i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
PromotionsSummary AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(cs.cs_order_number) AS num_catalog_sales,
        COUNT(ws.ws_order_number) AS num_web_sales,
        SUM(COALESCE(cs.cs_net_profit, 0)) + SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit
    FROM 
        promotion AS p
    LEFT JOIN 
        catalog_sales AS cs ON p.p_promo_sk = cs.cs_promo_sk
    LEFT JOIN 
        web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_net_profit,
    cs.total_orders,
    cs.avg_purchase_estimate,
    wi.w_warehouse_sk,
    wi.w_warehouse_name,
    wi.total_quantity,
    ps.p_promo_sk,
    ps.p_promo_name,
    ps.num_catalog_sales,
    ps.num_web_sales,
    ps.total_profit
FROM 
    CustomerStats AS cs
JOIN 
    WarehouseInventory AS wi ON MOD(cs.c_customer_sk, 10) = MOD(wi.w_warehouse_sk, 10)
JOIN 
    PromotionsSummary AS ps ON cs.total_net_profit >= 1000
ORDER BY 
    cs.total_net_profit DESC, ps.total_profit DESC
LIMIT 50;
