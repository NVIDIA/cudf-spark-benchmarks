
WITH RankedSales AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        RANK() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_net_paid_inc_tax) DESC) AS sales_rank
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
),
JoinedData AS (
    SELECT 
        cs.cs_bill_customer_sk AS customer_sk,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM RankedSales cs
    JOIN CustomerDemographics cd ON cs.cs_bill_customer_sk = cd.c_customer_sk
    WHERE cs.sales_rank <= 5
)
SELECT 
    jd.cd_gender,
    jd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(jd.total_sales) AS avg_sales
FROM JoinedData jd
GROUP BY 
    jd.cd_gender, 
    jd.cd_marital_status
HAVING AVG(jd.total_sales) > (
    SELECT AVG(total_sales) 
    FROM JoinedData 
)
ORDER BY 
    jd.cd_gender, 
    jd.cd_marital_status;
