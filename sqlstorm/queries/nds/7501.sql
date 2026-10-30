
WITH CustomerPromotions AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_ext_sales_price) AS avg_order_value,
        COUNT(DISTINCT p.p_promo_id) AS promo_used
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), FrequentCustomers AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        total_spent,
        total_orders,
        avg_order_value,
        promo_used,
        RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM 
        CustomerPromotions
)
SELECT 
    fc.c_customer_id,
    fc.c_first_name,
    fc.c_last_name,
    fc.total_spent,
    fc.total_orders,
    fc.avg_order_value,
    fc.promo_used
FROM 
    FrequentCustomers fc
WHERE 
    fc.spend_rank <= 10
ORDER BY 
    fc.total_spent DESC;
