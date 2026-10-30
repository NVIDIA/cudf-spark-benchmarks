
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cs.total_spent,
        cs.total_orders,
        cs.last_purchase_date
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales) 
        AND cs.total_orders > 5
),
PromotionsApplied AS (
    SELECT 
        hvc.customer_id,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_orders
    FROM 
        HighValueCustomers hvc
    JOIN 
        web_sales ws ON hvc.customer_id = ws.ws_bill_customer_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        hvc.customer_id, p.p_promo_name
)
SELECT 
    hvc.customer_id,
    hvc.total_spent,
    hvc.total_orders,
    hvc.last_purchase_date,
    COALESCE(SUM(p.promo_orders), 0) AS promotions_used
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    PromotionsApplied p ON hvc.customer_id = p.customer_id
GROUP BY 
    hvc.customer_id, hvc.total_spent, hvc.total_orders, hvc.last_purchase_date
ORDER BY 
    hvc.total_spent DESC
LIMIT 10;
