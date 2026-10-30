
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_month BETWEEN 1 AND 6
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month, c.c_birth_year

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        SUM(ss2.ss_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss2 ON c.c_customer_sk = ss2.ss_customer_sk
    WHERE 
        c.c_birth_month > 6
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month, c.c_birth_year
),

DemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sh.total_sales) AS sales_by_gender
    FROM 
        customer_demographics cd
    LEFT JOIN 
        SalesHierarchy sh ON cd.cd_demo_sk = sh.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)

SELECT 
    dd.cd_demo_sk,
    dd.cd_gender,
    dd.cd_marital_status,
    COALESCE(dd.sales_by_gender, 0) AS total_sales,
    RANK() OVER (PARTITION BY dd.cd_gender ORDER BY COALESCE(dd.sales_by_gender, 0) DESC) AS gender_sales_rank
FROM 
    DemographicDetails dd
WHERE 
    dd.sales_by_gender IS NOT NULL
OR 
    dd.sales_by_gender IS NULL

ORDER BY 
    dd.cd_gender, total_sales DESC;
