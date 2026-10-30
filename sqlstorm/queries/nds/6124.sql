
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        c.c_customer_sk
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
), 
SalesRank AS (
    SELECT 
        cs.c_customer_sk,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.cd_credit_rating,
    s.sales_rank,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(cs.total_store_sales, 0) AS total_store_sales
FROM 
    SalesRank s
JOIN 
    CustomerSales cs ON s.c_customer_sk = cs.c_customer_sk
JOIN 
    Demographics d ON cs.c_customer_sk = d.c_customer_sk
WHERE 
    s.sales_rank <= 100
ORDER BY 
    s.sales_rank;
