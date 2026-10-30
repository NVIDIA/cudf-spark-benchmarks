
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_sales_price) AS total_sales_amount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
SalesSummary AS (
    SELECT 
        hd_income_band_sk,
        hd_buy_potential,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(total_sales) AS total_sales_count,
        SUM(total_sales_amount) AS total_sales_amount,
        AVG(total_sales_amount) AS avg_sales_per_customer
    FROM 
        CustomerData
    GROUP BY 
        hd_income_band_sk, hd_buy_potential
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.customer_count,
    ss.total_sales_count,
    ss.total_sales_amount,
    ss.avg_sales_per_customer
FROM 
    SalesSummary ss
JOIN 
    income_band ib ON ss.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ib.ib_lower_bound;
