
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE 
        w.w_state IN ('CA', 'TX', 'NY')
    GROUP BY 
        w.w_warehouse_sk
),
PromotionsAnalysis AS (
    SELECT 
        p.p_promo_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discounts
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_sales,
    cs.avg_net_profit,
    ws.total_orders AS warehouse_orders,
    ws.total_sales AS warehouse_sales,
    pa.order_count AS promo_order_count,
    pa.total_discounts
FROM 
    CustomerSales cs
LEFT JOIN 
    WarehouseSales ws ON cs.c_customer_sk = ws.w_warehouse_sk
LEFT JOIN 
    PromotionsAnalysis pa ON cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
