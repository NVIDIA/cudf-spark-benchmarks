
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y' 
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity_sold,
        cs.total_sales,
        cs.total_orders,
        COALESCE(p.promo_order_count, 0) AS promo_order_count
    FROM 
        CustomerSales cs
    LEFT JOIN Promotions p ON cs.total_orders > 0 
    ORDER BY 
        cs.total_sales DESC
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_quantity_sold,
    ss.total_sales,
    ss.total_orders,
    ss.promo_order_count,
    CASE 
        WHEN ss.total_sales > 10000 THEN 'High'
        WHEN ss.total_sales > 5000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM 
    SalesSummary ss
WHERE 
    ss.total_sales IS NOT NULL
    AND ss.total_orders > 1
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    NULL AS c_first_name,
    NULL AS c_last_name,
    0 AS total_quantity_sold,
    0 AS total_sales,
    COUNT(*) AS total_orders,
    0 AS promo_order_count,
    'Aggregated' AS sales_category
FROM 
    SalesSummary
WHERE 
    promo_order_count = 0
GROUP BY 
    sales_category
ORDER BY 
    total_sales DESC NULLS LAST;
