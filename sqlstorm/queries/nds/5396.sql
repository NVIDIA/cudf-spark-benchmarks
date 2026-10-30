
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
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
),
SalesStatistics AS (
    SELECT 
        cs.c_customer_sk,
        SUM(cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cs.c_customer_sk
)
SELECT 
    s.c_customer_sk,
    s.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    CASE 
        WHEN s.total_sales > 1000 THEN 'High Value'
        WHEN s.total_sales > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesStatistics s
JOIN 
    CustomerDemographics cd ON s.c_customer_sk = cd.cd_demo_sk
ORDER BY 
    s.total_sales DESC
LIMIT 100;
