WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id
),
HighValueCustomers AS (
    SELECT
        cs.c_customer_id,
        cs.total_net_paid,
        cs.order_count,
        cs.last_purchase_date,
        DENSE_RANK() OVER (ORDER BY cs.total_net_paid DESC) AS customer_rank
    FROM
        CustomerSales cs
    WHERE 
        cs.total_net_paid IS NOT NULL
),
PromotionsAnalysis AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid) AS total_promo_sales
    FROM 
        promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
)
SELECT
    hvc.c_customer_id,
    hvc.total_net_paid,
    hvc.order_count,
    hvc.last_purchase_date,
    COALESCE(pa.total_promo_sales, 0) AS total_promo_sales,
    pa.promo_order_count AS promo_order_count
FROM
    HighValueCustomers hvc 
LEFT JOIN PromotionsAnalysis pa ON hvc.order_count < pa.promo_order_count
WHERE 
    hvc.customer_rank <= 10
ORDER BY 
    hvc.total_net_paid DESC, hvc.last_purchase_date DESC;