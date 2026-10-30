
WITH CustomerPerformance AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
PromotionPerformance AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_ext_sales_price) AS promo_sales,
        COUNT(ws.ws_order_number) AS promo_orders
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d)
        AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        p.p_promo_id
)
SELECT 
    cp.c_customer_id,
    cp.c_first_name,
    cp.c_last_name,
    cp.total_sales AS customer_total_sales,
    pp.promo_sales AS promo_total_sales,
    CASE 
        WHEN cp.total_sales > pp.promo_sales THEN 'Customer Performed Better'
        WHEN cp.total_sales < pp.promo_sales THEN 'Promotion Performed Better'
        ELSE 'Equal Performance'
    END AS performance_comparison
FROM 
    CustomerPerformance cp
FULL OUTER JOIN 
    PromotionPerformance pp ON cp.sales_rank = 1
WHERE 
    cp.total_orders > 5 OR pp.promo_orders > 5
ORDER BY 
    cp.total_sales DESC, pp.promo_sales DESC;
