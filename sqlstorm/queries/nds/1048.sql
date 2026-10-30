
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_dep_count) AS min_dependents
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        COALESCE(ss.total_store_orders, 0) AS total_store_orders,
        cd.max_purchase_estimate,
        cd.min_dependents,
        cs.sales_rank
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
    LEFT JOIN 
        CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        COALESCE(cs.total_web_sales, 0) > 1000 
        OR COALESCE(ss.total_store_sales, 0) > 1000
)
SELECT 
    *,
    CASE 
        WHEN total_web_sales > 0 AND total_store_sales > 0 THEN 'Both Sources'
        WHEN total_web_sales > 0 THEN 'Web Only'
        WHEN total_store_sales > 0 THEN 'Store Only'
        ELSE 'No Sales'
    END AS sales_source
FROM 
    FinalReport
WHERE 
    sales_rank <= 10
ORDER BY 
    total_web_sales DESC, total_store_sales DESC;
