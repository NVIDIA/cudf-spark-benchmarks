WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= 2458821 
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
PromotionStats AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
HighValuePromotions AS (
    SELECT 
        p.p_promo_id,
        promo_order_count,
        promo_sales,
        RANK() OVER (ORDER BY promo_sales DESC) AS sales_rank
    FROM 
        PromotionStats p
    WHERE 
        promo_sales > 10000 
)
SELECT 
    a.c_customer_id,
    b.p_promo_id,
    COALESCE(a.total_sales, 0) AS customer_total_sales,
    COALESCE(b.promo_sales, 0) AS promotion_total_sales,
    CASE 
        WHEN a.total_sales IS NULL THEN 'No Sales'
        WHEN b.promo_sales IS NULL THEN 'No Promotions'
        ELSE 'Sales and Promotions Found'
    END AS sales_promotion_status
FROM 
    TopCustomers a 
FULL OUTER JOIN 
    HighValuePromotions b ON a.sales_rank = b.sales_rank
WHERE 
    a.total_sales > 5000 OR b.promo_sales > 5000 
ORDER BY 
    customer_total_sales DESC, promotion_total_sales DESC;