
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_education_status IN ('Bachelor’s', 'Master’s')
    GROUP BY 
        c.c_customer_sk
), warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
), promotion_stats AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS usage_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_spent,
    ws.total_sales,
    ps.usage_count,
    ps.total_net_profit
FROM 
    customer_sales cs
JOIN 
    (SELECT DISTINCT ws_bill_customer_sk FROM web_sales) sub_ws ON cs.c_customer_sk = sub_ws.ws_bill_customer_sk
JOIN 
    promotion_stats ps ON ps.usage_count > 0
JOIN 
    warehouse_sales ws ON sub_ws.ws_bill_customer_sk = ws.w_warehouse_sk 
WHERE 
    cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
