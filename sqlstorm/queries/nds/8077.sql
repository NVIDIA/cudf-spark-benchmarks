
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        c.c_customer_id
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        ds.c_customer_id,
        d.cd_gender,
        d.cd_marital_status,
        COUNT(ds.total_sales) AS customer_count,
        SUM(ds.total_sales) AS total_revenue,
        AVG(ds.avg_sales) AS average_sales_per_customer
    FROM 
        CustomerSales ds
    JOIN 
        Demographics d ON ds.c_customer_id = d.c_customer_id
    GROUP BY 
        ds.c_customer_id, d.cd_gender, d.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(sa.customer_count) AS total_customers,
    SUM(sa.total_revenue) AS revenue_generated,
    AVG(sa.average_sales_per_customer) AS avg_sales
FROM 
    SalesAnalysis sa
JOIN 
    Demographics cd ON sa.c_customer_id = cd.c_customer_id
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    revenue_generated DESC, total_customers DESC;
