
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_sales_per_order
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesByPromotion AS (
    SELECT 
        ps.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid_inc_tax) AS promo_sales
    FROM 
        promotion ps
    JOIN 
        web_sales ws ON ps.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        ps.p_promo_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_orders,
        cs.total_sales,
        cs.avg_sales_per_order,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    tc.c_customer_id,
    tc.total_orders,
    tc.total_sales,
    tc.avg_sales_per_order,
    sp.promo_order_count,
    sp.promo_sales
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesByPromotion sp ON sp.promo_order_count > 0
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_sales DESC;
