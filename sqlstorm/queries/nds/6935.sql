
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c_customer_sk,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
SalesWithDemographics AS (
    SELECT 
        tc.c_customer_sk,
        tc.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        tc.sales_rank <= 10
)
SELECT 
    swd.cd_gender,
    swd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS customer_count,
    AVG(swd.total_sales) AS avg_sales
FROM 
    SalesWithDemographics swd
JOIN 
    income_band ib ON swd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    swd.cd_gender,
    swd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY 
    swd.cd_gender,
    swd.cd_marital_status,
    ib.ib_lower_bound;
