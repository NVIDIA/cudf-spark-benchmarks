
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.total_web_sales) AS web_sales,
        SUM(cs.total_catalog_sales) AS catalog_sales,
        SUM(cs.total_store_sales) AS store_sales
    FROM 
        CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    web_sales,
    catalog_sales,
    store_sales,
    (web_sales + catalog_sales + store_sales) AS total_sales
FROM 
    SalesByDemographics
ORDER BY 
    total_sales DESC
LIMIT 
    10;
