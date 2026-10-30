
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    cs.web_order_count,
    cs.catalog_order_count,
    cs.store_order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.avg_income_band
FROM 
    CustomerSales cs
LEFT JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cs.total_web_sales > 1000 OR cs.total_catalog_sales > 1000 OR cs.total_store_sales > 1000)
    AND (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
ORDER BY 
    cs.total_web_sales DESC NULLS LAST,
    cd.cd_purchase_estimate DESC
LIMIT 50;
