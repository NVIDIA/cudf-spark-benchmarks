
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesAnalytics AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        COUNT(cs.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS avg_sales,
        SUM(cs.total_transactions) AS total_transactions
    FROM 
        Demographics d
    JOIN 
        CustomerSales cs ON d.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        d.cd_gender, d.cd_marital_status, d.cd_education_status
)
SELECT 
    sa.cd_gender,
    sa.cd_marital_status,
    sa.cd_education_status,
    sa.customer_count,
    sa.avg_sales,
    sa.total_transactions
FROM 
    SalesAnalytics sa
WHERE 
    sa.avg_sales > (
        SELECT 
            AVG(avg_sales) 
        FROM 
            SalesAnalytics
    )
ORDER BY 
    sa.avg_sales DESC
LIMIT 10;
