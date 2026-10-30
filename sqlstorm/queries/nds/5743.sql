
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_purchase_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_purchase_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_purchase_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales,
        AVG(cs.store_purchase_count) AS avg_store_purchases,
        AVG(cs.catalog_purchase_count) AS avg_catalog_purchases,
        AVG(cs.web_purchase_count) AS avg_web_purchases
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    s.cd_gender, 
    s.cd_marital_status, 
    s.cd_education_status,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    s.avg_store_purchases,
    s.avg_catalog_purchases,
    s.avg_web_purchases
FROM 
    sales_summary s
WHERE 
    s.total_web_sales > 5000
ORDER BY 
    s.total_web_sales DESC;
