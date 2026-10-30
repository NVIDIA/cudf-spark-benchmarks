
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
SalesAggregate AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        ss.total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_combined_sales,
        CASE 
            WHEN COALESCE(cs.total_web_sales, 0) = 0 THEN 'No Web Sales'
            ELSE 'Has Web Sales'
        END AS web_sales_presence,
        COUNT(DISTINCT ss.s_store_sk) AS unique_stores_visited
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk IS NOT NULL OR ss.s_store_sk IS NOT NULL
    GROUP BY 
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name, 
        cs.total_web_sales, ss.total_store_sales
)
SELECT 
    sa.c_first_name,
    sa.c_last_name,
    sa.total_combined_sales,
    sa.web_sales_presence,
    sa.unique_stores_visited,
    (SELECT AVG(total_combined_sales) FROM SalesAggregate) AS average_sales,
    CASE 
        WHEN sa.total_combined_sales > (SELECT AVG(total_combined_sales) FROM SalesAggregate) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison,
    CASE 
        WHEN sa.total_combined_sales IS NULL THEN 'No Sales Data'
        ELSE 'Sales Data Present'
    END AS sales_data_status
FROM 
    SalesAggregate sa
WHERE 
    sa.total_combined_sales IS NOT NULL
ORDER BY 
    sa.total_combined_sales DESC
LIMIT 10;
