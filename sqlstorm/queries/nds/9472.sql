
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales
    FROM
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS customers_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON (cd.cd_demo_sk = c.c_current_cdemo_sk)
    JOIN 
        CustomerSales cs ON cs.c_customer_id = c.c_customer_id
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customers_count,
    COALESCE(SUM(cs.total_web_sales), 0) AS total_web_sales,
    COALESCE(SUM(cs.total_store_sales), 0) AS total_store_sales,
    COALESCE(SUM(cs.total_catalog_sales), 0) AS total_catalog_sales
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerSales cs ON cd.customers_count > 0
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.customers_count
ORDER BY 
    total_web_sales DESC, total_store_sales DESC;
