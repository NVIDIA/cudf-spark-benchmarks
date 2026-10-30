
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
average_sales AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        AVG(total_sales) AS avg_sales,
        AVG(total_transactions) AS avg_transactions
    FROM 
        customer_sales
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    a.cd_gender,
    a.cd_marital_status,
    a.cd_education_status,
    COALESCE(b.avg_sales, 0) AS avg_sales,
    b.avg_transactions
FROM 
    (SELECT DISTINCT cd_gender, cd_marital_status, cd_education_status FROM customer_demographics) a
LEFT JOIN 
    average_sales b ON a.cd_gender = b.cd_gender 
                    AND a.cd_marital_status = b.cd_marital_status 
                    AND a.cd_education_status = b.cd_education_status
ORDER BY 
    a.cd_gender, a.cd_marital_status, a.cd_education_status;
