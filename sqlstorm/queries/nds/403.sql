
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT *
    FROM CustomerOrderSummary
    WHERE spending_rank <= 10
),
PromotionsSummary AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    h.c_customer_id,
    CONCAT(h.c_first_name, ' ', h.c_last_name) AS full_name,
    h.total_spent,
    p.p_promo_name AS promo_name,
    p.order_count,
    p.total_revenue
FROM 
    HighSpenders h
LEFT JOIN 
    PromotionsSummary p ON h.total_spent > 1000 AND h.total_orders > 5
ORDER BY 
    h.total_spent DESC
LIMIT 50;
