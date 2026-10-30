
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), RankedSales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.total_web_sales,
        c.total_catalog_sales,
        c.num_web_orders,
        c.num_catalog_orders,
        RANK() OVER (ORDER BY c.total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY c.total_catalog_sales DESC) AS catalog_sales_rank
    FROM 
        CustomerSales c
), BestCustomers AS (
    SELECT 
        r.customer_id,
        r.total_web_sales,
        r.total_catalog_sales,
        r.num_web_orders,
        r.num_catalog_orders,
        CASE 
            WHEN r.num_web_orders > r.num_catalog_orders THEN 'Better Web Based'
            WHEN r.num_web_orders < r.num_catalog_orders THEN 'Better Catalog Based'
            ELSE 'Equal Performance'
        END AS sales_analysis
    FROM 
        RankedSales r
    WHERE 
        r.web_sales_rank <= 10 OR r.catalog_sales_rank <= 10
)
SELECT 
    b.customer_id,
    b.total_web_sales,
    b.total_catalog_sales,
    b.num_web_orders,
    b.num_catalog_orders,
    b.sales_analysis
FROM 
    BestCustomers b
WHERE 
    b.total_web_sales IS NOT NULL 
    OR b.total_catalog_sales IS NOT NULL;
