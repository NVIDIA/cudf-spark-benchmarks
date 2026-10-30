
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
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
IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(h.hd_income_band_sk) AS income_band
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        h.hd_demo_sk
),
SalesPerformance AS (
    SELECT 
        cd.cd_gender,
        COALESCE(SUM(cs.total_catalog_sales), 0) AS total_catalog_sales,
        COALESCE(SUM(cs.total_web_sales), 0) AS total_web_sales,
        COALESCE(SUM(cs.total_store_sales), 0) AS total_store_sales
    FROM 
        CustomerSales cs
    LEFT JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN 
        IncomeDemographics id ON cd.cd_demo_sk = id.hd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender AS gender,
    sp.total_catalog_sales,
    sp.total_web_sales,
    sp.total_store_sales,
    (sp.total_catalog_sales + sp.total_web_sales + sp.total_store_sales) AS total_sales,
    ROUND((sp.total_catalog_sales + sp.total_web_sales + sp.total_store_sales) / NULLIF(sp.total_catalog_sales + sp.total_web_sales + sp.total_store_sales, 0), 2) AS average_sales_per_customer
FROM 
    SalesPerformance sp
JOIN 
    customer_demographics cd ON sp.cd_gender = cd.cd_gender
ORDER BY 
    total_sales DESC;
