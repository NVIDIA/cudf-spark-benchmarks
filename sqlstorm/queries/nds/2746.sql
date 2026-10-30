
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count,
        MAX(ss.ss_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk
), 
SalesDetails AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.sales_count,
        cs.last_purchase_date,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales IS NOT NULL
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 5000
)

SELECT 
    cd.cd_demo_sk,
    COALESCE(sd.sales_rank, 0) AS rank,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    sd.total_sales,
    sd.sales_count,
    sd.last_purchase_date
FROM 
    CustomerDemographics cd
LEFT JOIN 
    SalesDetails sd ON cd.cd_demo_sk = sd.c_customer_sk
WHERE 
    sd.total_sales IS NOT NULL OR sd.c_customer_sk IS NULL
ORDER BY 
    sd.total_sales DESC NULLS LAST, cd.cd_marital_status;
