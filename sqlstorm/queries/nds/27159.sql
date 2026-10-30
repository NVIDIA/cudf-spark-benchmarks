
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name ASC, c.c_first_name ASC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerDetails AS (
    SELECT 
        rc.c_customer_sk,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = rc.c_customer_sk) AS total_sales
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn <= 10
),
AggregatedData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS customer_count,
        SUM(cd.total_sales) AS total_sales
    FROM 
        CustomerDetails cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    customer_count,
    total_sales,
    ROUND(total_sales / NULLIF(customer_count, 0), 2) AS avg_sales_per_customer
FROM 
    AggregatedData
ORDER BY 
    cd_gender, cd_marital_status, cd_education_status;
