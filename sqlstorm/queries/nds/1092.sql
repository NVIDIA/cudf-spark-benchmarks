
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) + COALESCE(SUM(cs.cs_net_paid), 0) + COALESCE(SUM(ss.ss_net_paid), 0) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
        AND cs.sales_rank <= 10
)
SELECT 
    t.c_customer_id,
    t.total_sales,
    t.cd_gender,
    t.cd_marital_status,
    CASE 
        WHEN t.cd_gender = 'M' THEN 'Male'
        WHEN t.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    CONCAT('Total Sales: $', ROUND(t.total_sales, 2)) AS sales_summary
FROM 
    TopSales t
ORDER BY 
    t.total_sales DESC;
