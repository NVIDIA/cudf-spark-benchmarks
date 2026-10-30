
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_sales_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_sales_count
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
SalesPerformance AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.web_sales_count,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        COALESCE(ss.store_sales_count, 0) AS store_sales_count,
        (COALESCE(cs.total_web_sales, 0) - COALESCE(ss.total_store_sales, 0)) AS net_sales_difference
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
),
RankedSales AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY net_sales_difference DESC) AS sales_rank
    FROM 
        SalesPerformance c
    WHERE 
        c.net_sales_difference IS NOT NULL
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_store_sales,
    r.net_sales_difference,
    r.sales_rank,
    CASE 
        WHEN r.net_sales_difference > 0 THEN 'Web Sales Higher'
        WHEN r.net_sales_difference < 0 THEN 'Store Sales Higher'
        ELSE 'Equal'
    END AS sales_comparison
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 100
ORDER BY 
    r.sales_rank;
