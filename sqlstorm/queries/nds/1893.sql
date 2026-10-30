
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
Sales_Ranking AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
),
High_Income_Customers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_upper_bound > 100000
),
Final_Report AS (
    SELECT 
        sr.sales_rank,
        cic.c_current_addr_sk,
        cic.c_first_name,
        cic.c_last_name,
        COALESCE(hic.cd_gender, 'Unknown') AS gender,
        COALESCE(hic.cd_marital_status, 'Unknown') AS marital_status,
        sr.total_sales
    FROM 
        Sales_Ranking sr
    JOIN 
        customer cic ON sr.c_customer_sk = cic.c_customer_sk
    LEFT JOIN 
        High_Income_Customers hic ON cic.c_current_cdemo_sk = hic.cd_demo_sk
)
SELECT 
    fr.sales_rank,
    CONCAT(fr.c_first_name, ' ', fr.c_last_name) AS full_name,
    fr.gender,
    fr.marital_status,
    fr.total_sales
FROM 
    Final_Report fr
WHERE 
    fr.sales_rank <= 50
ORDER BY 
    fr.total_sales DESC;
