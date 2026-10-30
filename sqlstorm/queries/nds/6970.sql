
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_dep_count) AS avg_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),

WebSalesStats AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_web_site_sk
),

StoreSalesStats AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),

SummaryStats AS (
    SELECT 
        cs.customer_count,
        cs.total_purchase_estimate,
        cs.avg_dependents,
        ws.total_sales AS web_sales,
        ss.total_store_sales AS store_sales
    FROM 
        CustomerStats cs
    JOIN 
        WebSalesStats ws ON cs.customer_count > 100
    JOIN 
        StoreSalesStats ss ON ws.total_orders > 50
)

SELECT 
    customer_count,
    total_purchase_estimate,
    avg_dependents,
    web_sales,
    store_sales,
    (web_sales + store_sales) AS total_sales_combined
FROM 
    SummaryStats
ORDER BY 
    total_sales_combined DESC
LIMIT 10;
