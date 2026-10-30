
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),

high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        CASE 
            WHEN cs.total_web_sales > 5000 THEN 'High Web Spender'
            WHEN cs.total_catalog_sales > 5000 THEN 'High Catalog Spender'
            WHEN cs.total_store_sales > 5000 THEN 'High Store Spender'
            ELSE 'Regular Customer'
        END AS customer_category
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
),

sales_summary AS (
    SELECT 
        hvc.customer_category,
        COUNT(hvc.c_customer_id) AS customer_count,
        AVG(hvc.total_web_sales) AS avg_web_sales,
        AVG(hvc.total_catalog_sales) AS avg_catalog_sales,
        AVG(hvc.total_store_sales) AS avg_store_sales
    FROM 
        high_value_customers hvc
    GROUP BY 
        hvc.customer_category
)

SELECT 
    s.customer_category,
    s.customer_count,
    s.avg_web_sales,
    s.avg_catalog_sales,
    s.avg_store_sales,
    COALESCE(s.avg_web_sales, 0) - COALESCE(s.avg_catalog_sales, 0) AS sales_diff
FROM 
    sales_summary s
UNION ALL
SELECT 
    'Overall' AS customer_category,
    COUNT(c.c_customer_id) AS customer_count,
    AVG(cs.total_web_sales) AS avg_web_sales,
    AVG(cs.total_catalog_sales) AS avg_catalog_sales,
    AVG(cs.total_store_sales) AS avg_store_sales,
    COALESCE(AVG(cs.total_web_sales), 0) - COALESCE(AVG(cs.total_catalog_sales), 0) AS sales_diff
FROM 
    customer c
LEFT JOIN 
    customer_sales cs ON c.c_customer_id = cs.c_customer_id
GROUP BY 
    c.c_customer_id
ORDER BY 
    customer_category;
