
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
GenderAnalysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS num_customers,
        AVG(total_sales) AS avg_sales,
        AVG(total_transactions) AS avg_transactions
    FROM 
        SalesData
    GROUP BY 
        cd_gender
),
EducationAnalysis AS (
    SELECT 
        cd_education_status,
        COUNT(*) AS num_customers,
        AVG(total_sales) AS avg_sales,
        AVG(total_transactions) AS avg_transactions
    FROM 
        SalesData
    GROUP BY 
        cd_education_status
)
SELECT 
    ga.cd_gender,
    ga.num_customers AS gender_customer_count,
    ga.avg_sales AS gender_avg_sales,
    ea.cd_education_status,
    ea.num_customers AS education_customer_count,
    ea.avg_sales AS education_avg_sales
FROM 
    GenderAnalysis ga
CROSS JOIN 
    EducationAnalysis ea
WHERE 
    ga.avg_sales > (SELECT AVG(total_sales) FROM SalesData) 
    AND ea.avg_sales > (SELECT AVG(total_sales) FROM SalesData)
ORDER BY 
    ga.cd_gender, ea.cd_education_status;
