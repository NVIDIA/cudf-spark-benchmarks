
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count,
        AVG(CASE WHEN cd.cd_gender = 'M' THEN ws.ws_sales_price ELSE NULL END) AS avg_male_sale,
        AVG(CASE WHEN cd.cd_gender = 'F' THEN ws.ws_sales_price ELSE NULL END) AS avg_female_sale
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_id,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        warehouse AS w
    JOIN 
        web_sales AS ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
PromotionsImpact AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count
    FROM 
        promotion AS p
    LEFT JOIN 
        web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.purchase_count,
    cs.avg_male_sale,
    cs.avg_female_sale,
    wp.w_warehouse_id,
    wp.avg_net_profit,
    wp.total_orders,
    pi.p_promo_id,
    pi.total_net_paid,
    pi.promo_order_count
FROM 
    CustomerSales AS cs
LEFT JOIN 
    WarehousePerformance AS wp ON cs.purchase_count = wp.total_orders
LEFT JOIN 
    PromotionsImpact AS pi ON cs.total_sales > 1000 
ORDER BY 
    cs.total_sales DESC, wp.avg_net_profit DESC;
