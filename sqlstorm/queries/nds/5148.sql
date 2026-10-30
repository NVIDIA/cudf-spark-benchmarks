
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_store_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM CustomerSales cs
    JOIN CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY cs.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
)
SELECT 
    SUM(total_catalog_sales) AS total_catalog_sales,
    SUM(total_store_sales) AS total_store_sales,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS customer_count
FROM SalesSummary
GROUP BY cd_gender, cd_marital_status, cd_education_status
ORDER BY total_catalog_sales DESC, total_store_sales DESC;
