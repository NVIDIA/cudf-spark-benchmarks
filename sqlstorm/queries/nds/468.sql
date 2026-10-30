
WITH CustomerCounts AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
TopPromotions AS (
    SELECT 
        p_promo_id,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    JOIN 
        promotion ON ws_promo_sk = p_promo_sk
    GROUP BY 
        p_promo_id 
    HAVING 
        SUM(ws_net_paid) > 100000
),
WarehouseInventory AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory AS inv
    JOIN 
        warehouse AS w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
SalesDetails AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_net_paid) AS daily_sales,
        COUNT(ws.ws_order_number) AS daily_orders
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    cc.cd_gender,
    cc.customer_count,
    cc.total_estimate,
    cc.avg_dep_count,
    tp.p_promo_id,
    tp.total_sales,
    tp.order_count,
    wi.w_warehouse_id,
    wi.total_inventory,
    sd.daily_sales,
    sd.daily_orders
FROM 
    CustomerCounts AS cc
LEFT JOIN 
    TopPromotions AS tp ON tp.total_sales IS NOT NULL
LEFT JOIN 
    WarehouseInventory AS wi ON wi.total_inventory IS NOT NULL
JOIN 
    SalesDetails AS sd ON sd.daily_orders > 0
WHERE 
    cc.customer_count > 100
ORDER BY 
    cc.cd_gender, tp.total_sales DESC, sd.daily_sales DESC;
