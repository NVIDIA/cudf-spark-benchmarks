
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
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
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(c.c_customer_sk) AS number_of_customers,
        AVG(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_ratio,
        AVG(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_ratio
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    d.number_of_customers,
    d.female_ratio,
    d.married_ratio
FROM 
    CustomerSales cs
JOIN 
    Demographics d ON cs.c_customer_sk = d.cd_demo_sk
WHERE 
    cs.total_web_sales > 1000 OR cs.total_catalog_sales > 1000 OR cs.total_store_sales > 1000
ORDER BY 
    cs.total_web_sales DESC, cs.total_catalog_sales DESC, cs.total_store_sales DESC
LIMIT 100;
