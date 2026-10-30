
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
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cd.gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_sales_value,
    AVG(total_sales) AS avg_sales_value
FROM 
    SalesSummary
GROUP BY 
    gender, cd_marital_status, cd_education_status
ORDER BY 
    total_sales_value DESC;
