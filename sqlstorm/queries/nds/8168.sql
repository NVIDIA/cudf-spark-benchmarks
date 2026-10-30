
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_revenue
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_credit_rating = 'Excellent'
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.hd_income_band_sk,
        SUM(cs.total_revenue) AS total_revenue,
        COUNT(DISTINCT cs.total_sales) AS sales_count
    FROM 
        CustomerSales cs
    JOIN 
        Demographics d ON cs.c_customer_sk = d.cd_demo_sk
    GROUP BY 
        cs.c_customer_sk, d.cd_gender, d.cd_marital_status, d.hd_income_band_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.hd_income_band_sk,
    AVG(ss.total_revenue) AS avg_revenue,
    SUM(ss.sales_count) AS total_sales
FROM 
    SalesSummary ss
JOIN 
    Demographics d ON ss.c_customer_sk = d.cd_demo_sk
GROUP BY 
    d.cd_gender, d.cd_marital_status, d.hd_income_band_sk
ORDER BY 
    avg_revenue DESC
LIMIT 10;
