
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
), PromotionStats AS (
    SELECT 
        ps.p_promo_name,
        SUM(ws.ws_net_profit) AS promo_profit,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders
    FROM 
        promotion ps
    JOIN 
        web_sales ws ON ps.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        ps.p_promo_name
), TopPromotions AS (
    SELECT 
        p.p_promo_name,
        p.promo_profit,
        p.promo_orders,
        RANK() OVER (ORDER BY p.promo_profit DESC) AS promo_rank
    FROM 
        PromotionStats p
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    COUNT(tp.p_promo_name) AS applied_promotions,
    MAX(tp.promo_rank) AS highest_promo_rank,
    SUM(cs.total_profit) AS customer_total_profit,
    AVG(cs.total_orders) AS avg_orders_per_customer
FROM 
    CustomerStats cs
LEFT JOIN 
    TopPromotions tp ON tp.promo_orders > 0
GROUP BY 
    cs.c_first_name, cs.c_last_name, cs.cd_gender, cs.cd_marital_status
ORDER BY 
    customer_total_profit DESC
LIMIT 100;
