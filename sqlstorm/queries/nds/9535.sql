
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
SalesRank AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    dr.cd_gender, 
    dr.cd_marital_status, 
    dr.cd_education_status, 
    COUNT(sr.c_customer_sk) AS number_of_customers,
    AVG(sr.total_sales) AS average_sales,
    MAX(sr.sales_rank) AS highest_sales_rank
FROM 
    Demographics dr
JOIN 
    SalesRank sr ON dr.cd_demo_sk = sr.c_customer_sk
WHERE 
    sr.sales_rank <= 100
GROUP BY 
    dr.cd_gender, 
    dr.cd_marital_status, 
    dr.cd_education_status
ORDER BY 
    number_of_customers DESC, 
    average_sales DESC;
