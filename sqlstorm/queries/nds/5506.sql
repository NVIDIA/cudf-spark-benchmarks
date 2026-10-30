
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        c.c_customer_id, 
        COALESCE(cs.total_web_sales, 0) AS total_web_sales, 
        COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales, 
        COALESCE(cs.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS grand_total_sales
    FROM 
        customer c
    LEFT JOIN 
        CustomerSales cs ON c.c_customer_id = cs.c_customer_id
),
RankedSales AS (
    SELECT 
        cs.c_customer_id AS customer_id,
        ss.total_web_sales,
        ss.total_catalog_sales,
        ss.total_store_sales,
        ss.grand_total_sales,
        RANK() OVER (ORDER BY ss.grand_total_sales DESC) AS sales_rank
    FROM 
        SalesSummary ss
    JOIN 
        CustomerSales cs ON cs.c_customer_id = ss.c_customer_id
)
SELECT 
    rs.customer_id, 
    rs.total_web_sales, 
    rs.total_catalog_sales, 
    rs.total_store_sales, 
    rs.grand_total_sales, 
    rs.sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;
