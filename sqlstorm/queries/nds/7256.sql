
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
sales_analysis AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        cs.total_sales,
        cs.total_transactions,
        DENSE_RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_summary cs
),
gender_sales AS (
    SELECT 
        cs.cd_gender,
        AVG(cs.total_sales) AS avg_sales,
        MIN(cs.total_sales) AS min_sales,
        MAX(cs.total_sales) AS max_sales,
        COUNT(*) AS customer_count
    FROM 
        sales_analysis cs
    GROUP BY 
        cs.cd_gender
)
SELECT 
    g.cd_gender,
    g.avg_sales,
    g.min_sales,
    g.max_sales,
    g.customer_count,
    CASE 
        WHEN g.avg_sales > 500 THEN 'High Value'
        WHEN g.avg_sales BETWEEN 200 AND 500 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    gender_sales g
WHERE 
    g.customer_count > 100
ORDER BY 
    g.avg_sales DESC;
