
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
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
RankedCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id, 
        c.total_web_sales,
        c.total_catalog_sales,
        c.total_store_sales,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(c.total_web_sales, 0) + COALESCE(c.total_catalog_sales, 0) + COALESCE(c.total_store_sales, 0)) DESC) AS rank
    FROM 
        CustomerSales c
),
SalesSummary AS (
    SELECT 
        DENSE_RANK() OVER (ORDER BY total_web_sales DESC) AS web_rank,
        DENSE_RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_rank,
        DENSE_RANK() OVER (ORDER BY total_store_sales DESC) AS store_rank,
        total_web_sales,
        total_catalog_sales,
        total_store_sales
    FROM 
        CustomerSales
)

SELECT 
    rc.customer_id,
    rc.total_web_sales,
    rc.total_catalog_sales,
    rc.total_store_sales,
    ss.web_rank,
    ss.catalog_rank,
    ss.store_rank
FROM 
    RankedCustomers rc
JOIN 
    SalesSummary ss ON rc.total_web_sales = ss.total_web_sales AND rc.total_catalog_sales = ss.total_catalog_sales AND rc.total_store_sales = ss.total_store_sales
WHERE 
    rc.rank <= 100
ORDER BY 
    rc.total_web_sales DESC, 
    rc.total_catalog_sales DESC, 
    rc.total_store_sales DESC;
