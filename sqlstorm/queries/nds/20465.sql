WITH customer_with_revenue AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_revenue,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_revenue,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS web_rank,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS catalog_rank,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS store_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
), 
combined_revenue AS (
    SELECT 
        cwr.c_customer_sk,
        cwr.c_customer_id,
        COALESCE(cwr.total_web_revenue, 0) AS total_revenue,
        cwr.web_order_count,
        cwr.catalog_order_count,
        cwr.store_order_count,
        CASE 
            WHEN cwr.web_rank = 1 THEN 'Top Web Customer' 
            WHEN cwr.catalog_rank = 1 THEN 'Top Catalog Customer' 
            WHEN cwr.store_rank = 1 THEN 'Top Store Customer' 
            ELSE 'Regular Customer' 
        END AS customer_category
    FROM 
        customer_with_revenue cwr
), 
revenue_summary AS (
    SELECT 
        customer_category,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(total_revenue) AS total_revenue_by_category,
        AVG(total_revenue) AS avg_revenue_per_customer
    FROM 
        combined_revenue
    GROUP BY 
        customer_category
)
SELECT 
    rs.customer_category,
    rs.unique_customers,
    rs.total_revenue_by_category,
    rs.avg_revenue_per_customer,
    CASE 
        WHEN rs.avg_revenue_per_customer > (SELECT AVG(total_revenue) FROM combined_revenue) THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS revenue_comparison
FROM 
    revenue_summary rs
ORDER BY 
    rs.total_revenue_by_category DESC;