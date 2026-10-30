
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price * cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price * ss.ss_quantity), 0) AS total_store_sales
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Sales_Comparison AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        CASE 
            WHEN cs.total_web_sales > cs.total_store_sales THEN 'Web Sales Lead'
            WHEN cs.total_store_sales > cs.total_web_sales THEN 'Store Sales Lead'
            ELSE 'Equal Sales'
        END AS sales_lead,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                             WHEN cs.total_web_sales > cs.total_store_sales THEN 'Web Sales Lead'
                                             WHEN cs.total_store_sales > cs.total_web_sales THEN 'Store Sales Lead'
                                             ELSE 'Equal Sales'
                                         END ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    sc.c_customer_sk,
    sc.c_first_name,
    sc.c_last_name,
    sc.total_web_sales,
    sc.total_catalog_sales,
    sc.total_store_sales,
    sc.sales_lead,
    CASE 
        WHEN sc.sales_lead = 'Web Sales Lead' AND sc.total_web_sales IS NOT NULL THEN 'Promote Web'
        WHEN sc.sales_lead = 'Store Sales Lead' AND sc.total_store_sales IS NOT NULL THEN 'Promote Store'
        ELSE 'No Promotion'
    END AS promotion_strategy,
    (SELECT COUNT(*) FROM Sales_Comparison WHERE sales_rank = 1 AND sales_lead = sc.sales_lead) AS total_leads
FROM 
    Sales_Comparison sc
WHERE 
    sc.total_web_sales IS NOT NULL OR sc.total_store_sales IS NOT NULL
ORDER BY 
    sc.sales_lead, sc.total_web_sales DESC;
