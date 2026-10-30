
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        average_order_value,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
RecentPromotions AS (
    SELECT 
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(ws.ws_order_number) AS promo_sales_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_current_year = 'Y')
        AND p.p_end_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_current_year = 'Y')
    GROUP BY 
        p.p_promo_id, p.p_start_date_sk, p.p_end_date_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.order_count,
    hvc.average_order_value,
    rp.promo_sales_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentPromotions rp ON hvc.order_count > 10
WHERE 
    hvc.sales_rank <= 100
ORDER BY 
    hvc.total_sales DESC;
