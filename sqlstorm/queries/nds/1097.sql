
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid_inc_tax, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_store_sales,
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
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate < 500 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer_demographics cd
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.purchase_category,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) AS total_sales,
    DENSE_RANK() OVER (ORDER BY COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) DESC) AS sales_rank
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'F' AND cs.total_web_sales > 1000) OR (cd.cd_gender = 'M' AND cs.total_catalog_sales > 2000)
ORDER BY 
    total_sales DESC
LIMIT 100;
