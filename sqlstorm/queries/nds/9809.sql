
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), RankedCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_profit,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS sales_rank
    FROM 
        CustomerSales cs
), PromoStats AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_profit) AS promo_total_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
), BestPromo AS (
    SELECT 
        ps.p_promo_id,
        ps.promo_order_count,
        ps.promo_total_profit,
        RANK() OVER (ORDER BY ps.promo_total_profit DESC) AS promo_rank
    FROM 
        PromoStats ps
)
SELECT 
    rc.c_customer_id,
    rc.total_profit,
    rc.order_count,
    bp.p_promo_id,
    bp.promo_order_count,
    bp.promo_total_profit
FROM 
    RankedCustomers rc
JOIN 
    BestPromo bp ON rc.sales_rank <= 10 AND bp.promo_order_count > 0
WHERE 
    rc.total_profit > 1000
ORDER BY 
    rc.total_profit DESC, bp.promo_total_profit DESC;
