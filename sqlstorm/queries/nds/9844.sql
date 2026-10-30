
WITH SalesData AS (
    SELECT 
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        s_city,
        s_state
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_city, s_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_dep_count) AS average_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
PromotionData AS (
    SELECT 
        p.p_promo_name,
        SUM(cs_ext_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    SD.s_city,
    SD.s_state,
    SD.total_sales,
    SD.unique_customers,
    CD.cd_gender,
    CD.cd_marital_status,
    CD.average_dependents,
    PD.promo_sales
FROM 
    SalesData SD
JOIN 
    CustomerDemographics CD ON SD.unique_customers > 100
JOIN 
    PromotionData PD ON PD.promo_sales > 1000
ORDER BY 
    SD.total_sales DESC;
