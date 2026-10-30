WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit_per_order,
        MAX(ws.ws_sales_price) AS highest_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F' 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid_inc_tax) AS promo_total_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_id
),
TopItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30  
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_revenue DESC
    LIMIT 10
)

SELECT 
    cs.c_customer_id,
    cs.total_orders,
    cs.total_spent,
    cs.avg_profit_per_order,
    cs.highest_order_value,
    p.promo_order_count,
    p.promo_total_revenue,
    ti.total_quantity_sold,
    ti.total_revenue
FROM 
    CustomerSummary cs
LEFT JOIN 
    Promotions p ON cs.total_orders > 0
LEFT JOIN 
    TopItems ti ON ti.total_quantity_sold > 0 
ORDER BY 
    cs.total_spent DESC, p.promo_total_revenue DESC;