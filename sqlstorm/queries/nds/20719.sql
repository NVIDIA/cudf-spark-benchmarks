
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN ws_ship_date_sk IS NOT NULL THEN ws_net_paid ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs_ship_date_sk IS NOT NULL THEN cs_net_paid ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss_sold_date_sk IS NOT NULL THEN ss_net_paid ELSE 0 END) AS total_store_sales,
        COALESCE(SUM(CASE WHEN ss_sold_date_sk IS NOT NULL THEN ss_net_profit ELSE 0 END), 0) AS total_store_net_profit,
        COALESCE(SUM(CASE WHEN ws_ship_date_sk IS NOT NULL THEN ws_net_profit ELSE 0 END), 0) AS total_web_net_profit,
        MAX(COALESCE(cd_purchase_estimate, 0)) AS max_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
sales_ranked AS (
    SELECT 
        c.c_customer_sk,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS sales_rank
    FROM 
        customer_sales cs
    INNER JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    LEFT JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    LEFT JOIN 
        store_sales ss ON p.p_promo_sk = ss.ss_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    cr.sales_rank,
    p.p_promo_name,
    coalesce(cr.total_web_sales, 0) AS total_web_sales,
    coalesce(cr.total_catalog_sales, 0) AS total_catalog_sales,
    coalesce(cr.total_store_sales, 0) AS total_store_sales,
    CASE 
        WHEN cr.sales_rank = 1 AND (cr.total_web_sales + cr.total_catalog_sales + cr.total_store_sales) > 1000 
            THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    (SELECT COUNT(*) FROM promotions pr WHERE pr.total_web_orders > 10) AS active_web_promotions,
    (SELECT COUNT(*) FROM promotions pr WHERE pr.total_catalog_orders > 5) AS active_catalog_promotions
FROM 
    sales_ranked cr
LEFT JOIN 
    promotions p ON cr.sales_rank = 1
WHERE 
    (cr.total_web_sales + cr.total_catalog_sales + cr.total_store_sales) IS NOT NULL
ORDER BY 
    cr.sales_rank;
