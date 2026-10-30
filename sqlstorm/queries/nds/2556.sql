
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        c.c_customer_id
    FROM
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    cs.web_orders,
    cs.catalog_orders,
    cs.store_orders,
    CASE 
        WHEN cs.total_web_sales > 1000 THEN 'High Web Sales'
        WHEN cs.total_web_sales BETWEEN 500 AND 1000 THEN 'Medium Web Sales'
        ELSE 'Low Web Sales'
    END AS web_sales_category,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_store_sales DESC) AS store_sales_rank
FROM 
    customer_sales cs
JOIN 
    customer_demographics cd ON cd.c_customer_id = cs.c_customer_id
WHERE 
    cd.cd_marital_status = 'M' 
    OR cd.cd_purchase_estimate > 15000
ORDER BY 
    web_sales_category, cd.cd_gender, cs.total_store_sales DESC;
