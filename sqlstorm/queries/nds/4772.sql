
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_inc_tax
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
PromotionalSales AS (
    SELECT 
        p.p_promo_sk,
        SUM(ws.ws_net_paid) AS promo_sales,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p 
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_sales,
        ss.total_store_orders,
        ss.total_store_sales,
        COALESCE(ps.promo_sales, 0) AS promotional_sales,
        COALESCE(ps.promo_order_count, 0) AS promotional_order_count
    FROM 
        CustomerSales cs
    LEFT JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
    LEFT JOIN 
        PromotionalSales ps ON ss.s_store_sk = ps.p_promo_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    SalesSummary
WHERE 
    total_orders > 0
ORDER BY 
    customer_value DESC, total_sales DESC;
