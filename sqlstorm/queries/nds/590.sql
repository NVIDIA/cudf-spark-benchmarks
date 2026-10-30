
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_sales_price, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_sales_price, 0)) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (ORDER BY total_web_sales + total_catalog_sales + total_store_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    r.sales_rank,
    COALESCE(r.total_web_sales, 0) AS total_web_sales,
    COALESCE(r.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(r.total_store_sales, 0) AS total_store_sales,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top Customers'
        WHEN r.sales_rank <= 50 THEN 'Medium Customers'
        ELSE 'Low Customers'
    END AS customer_category
FROM 
    RankedSales r
WHERE 
    r.total_web_sales > 1000 OR r.total_catalog_sales > 1000 OR r.total_store_sales > 1000
ORDER BY 
    r.sales_rank
LIMIT 10 OFFSET 5;
