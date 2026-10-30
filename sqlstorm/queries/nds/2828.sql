
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_catalog_sales
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE 
        p.p_discount_active = 'Y' 
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
HighValuePromotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        p.total_catalog_sales,
        CASE 
            WHEN p.total_catalog_sales > 100000 THEN 'High Value'
            ELSE 'Regular'
        END AS promo_value_category
    FROM 
        Promotions p
)
SELECT 
    r.customer_name,
    r.total_web_sales,
    r.order_count,
    p.promo_value_category
FROM 
    (SELECT 
         CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
         cs.total_web_sales,
         cs.order_count
     FROM 
         RankedSales cs
     JOIN 
         customer c ON cs.c_customer_sk = c.c_customer_sk
     WHERE 
         cs.sales_rank <= 10) r
LEFT JOIN 
    HighValuePromotions p ON r.order_count = p.total_catalog_sales
WHERE 
    p.promo_value_category IS NOT NULL 
ORDER BY 
    r.total_web_sales DESC;
