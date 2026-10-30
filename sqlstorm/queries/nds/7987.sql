
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_sales
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
DemographicInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesPerformance AS (
    SELECT 
        ci.c_customer_sk,
        ci.total_web_sales,
        ci.total_catalog_sales,
        ci.total_store_sales,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_education_status,
        di.hd_income_band_sk,
        di.hd_buy_potential
    FROM 
        CustomerSales ci
    JOIN 
        DemographicInfo di ON ci.c_customer_sk = di.cd_demo_sk
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    di.hd_income_band_sk,
    di.hd_buy_potential
FROM 
    SalesPerformance di
GROUP BY 
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    di.hd_income_band_sk,
    di.hd_buy_potential
ORDER BY 
    total_customers DESC;
