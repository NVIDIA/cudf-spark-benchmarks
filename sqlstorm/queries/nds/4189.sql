
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
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
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesAggregation AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ws.total_web_sales, 0) AS web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        (COALESCE(ws.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales
    FROM 
        CustomerSales c
    LEFT JOIN 
        (SELECT c_customer_sk, SUM(total_web_sales) AS total_web_sales FROM CustomerSales GROUP BY c_customer_sk) ws ON c.c_customer_sk = ws.c_customer_sk
    LEFT JOIN 
        (SELECT c_customer_sk, SUM(total_catalog_sales) AS total_catalog_sales FROM CustomerSales GROUP BY c_customer_sk) cs ON c.c_customer_sk = cs.c_customer_sk
    LEFT JOIN 
        (SELECT c_customer_sk, SUM(total_store_sales) AS total_store_sales FROM CustomerSales GROUP BY c_customer_sk) ss ON c.c_customer_sk = ss.c_customer_sk
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesAggregation
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.web_sales,
    r.catalog_sales,
    r.store_sales,
    r.total_sales,
    r.sales_rank,
    CASE 
        WHEN r.total_sales = 0 THEN 'No Sales'
        WHEN r.total_sales > 0 AND r.total_sales <= 1000 THEN 'Low Sales'
        WHEN r.total_sales > 1000 AND r.total_sales <= 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
