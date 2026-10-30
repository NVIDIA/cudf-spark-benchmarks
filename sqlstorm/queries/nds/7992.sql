
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN ib.ib_lower_bound || ' - ' || ib.ib_upper_bound 
            ELSE 'Unknown' 
        END AS income_band
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
SalesSummary AS (
    SELECT 
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        cd_gender,
        cd_marital_status,
        income_band,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_web_sales DESC) AS rank
    FROM 
        CustomerSales
)
SELECT 
    cd_gender,
    cd_marital_status,
    income_band,
    COUNT(*) AS num_customers,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM 
    SalesSummary
WHERE 
    rank <= 10
GROUP BY 
    cd_gender, cd_marital_status, income_band
ORDER BY 
    cd_gender, avg_web_sales DESC;
