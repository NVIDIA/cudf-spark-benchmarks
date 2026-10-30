WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2458849 AND 2459200 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopSalesCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_sales
    FROM 
        RankedCustomers rc
    WHERE 
        rc.sales_rank <= 5  
)
SELECT 
    tsc.cd_gender,
    COUNT(tsc.c_customer_sk) AS top_customers_count,
    AVG(tsc.total_sales) AS avg_sales,
    MAX(tsc.total_sales) AS max_sales
FROM 
    TopSalesCustomers tsc
GROUP BY 
    tsc.cd_gender
ORDER BY 
    tsc.cd_gender;