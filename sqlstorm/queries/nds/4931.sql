
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_dep_count >= 2
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        SUM(cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name
),
TopSales AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_sales,
        s.sales_rank,
        CASE 
            WHEN s.total_sales IS NULL THEN 'NO SALES' 
            WHEN s.total_sales >= 100000 THEN 'HIGH ROLLER' 
            ELSE 'REGULAR'
        END AS customer_type
    FROM 
        SalesSummary s
)

SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.sales_rank,
    t.customer_type
FROM 
    TopSales t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
