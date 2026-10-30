
WITH AggregatedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        AggregatedSales
)
SELECT 
    rs.c_customer_id,
    rs.total_web_sales,
    rs.total_catalog_sales,
    rs.total_store_sales,
    rs.web_order_count,
    rs.catalog_order_count,
    rs.store_order_count,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.cd_education_status
FROM 
    RankedSales rs
WHERE 
    (rs.web_sales_rank <= 10 OR rs.catalog_sales_rank <= 10 OR rs.store_sales_rank <= 10)
ORDER BY 
    rs.total_web_sales DESC, 
    rs.total_catalog_sales DESC,
    rs.total_store_sales DESC;
