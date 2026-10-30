
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_sales, 
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), 
PromotionalSales AS (
    SELECT 
        p.p_promo_id, 
        SUM(ws.ws_net_paid) AS promo_total_sales,
        COUNT(ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id AS customer_id,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS customer_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.customer_id, 
    tc.total_sales,
    ps.promo_total_sales,
    ps.promo_order_count
FROM 
    TopCustomers tc
LEFT JOIN 
    PromotionalSales ps ON ps.promo_total_sales > 0
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_sales DESC;
