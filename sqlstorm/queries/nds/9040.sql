
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(CASE WHEN ws_sold_date_sk BETWEEN 20200101 AND 20201231 THEN ws_ext_sales_price ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs_sold_date_sk BETWEEN 20200101 AND 20201231 THEN cs_ext_sales_price ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss_sold_date_sk BETWEEN 20200101 AND 20201231 THEN ss_ext_sales_price ELSE 0 END) AS total_store_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
RankedSales AS (
    SELECT 
        c.*,
        RANK() OVER (PARTITION BY c.cd_gender ORDER BY (c.total_web_sales + c.total_catalog_sales + c.total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerData c
)
SELECT 
    r.c_customer_id, 
    r.cd_gender, 
    r.cd_marital_status, 
    r.cd_education_status, 
    r.total_web_sales, 
    r.total_catalog_sales, 
    r.total_store_sales,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.cd_gender, r.total_web_sales DESC;
