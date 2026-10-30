
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesData AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS total_sales
    FROM 
        CustomerSales cs
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(sd.c_customer_sk) AS customer_count,
    SUM(sd.web_sales) AS total_web_sales,
    SUM(sd.catalog_sales) AS total_catalog_sales,
    SUM(sd.store_sales) AS total_store_sales,
    SUM(sd.total_sales) AS grand_total_sales
FROM 
    SalesData sd
JOIN customer_demographics cd ON sd.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    grand_total_sales DESC
LIMIT 10;
