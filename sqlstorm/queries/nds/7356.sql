
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales, 
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales, 
        SUM(ss.ss_ext_sales_price) AS total_store_sales 
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
SalesStatistic AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_web_sales, 
        cs.total_catalog_sales, 
        cs.total_store_sales,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
        CASE 
            WHEN (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) > 10000 THEN 'High'
            WHEN (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM CustomerSales cs
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status, 
    ss.total_sales, 
    ss.sales_category
FROM SalesStatistic ss
JOIN customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status = 'M'
AND ss.total_sales > 5000
ORDER BY ss.total_sales DESC;
