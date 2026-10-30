
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TotalSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        ss.total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_sales
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.c_customer_id
),
RankedSales AS (
    SELECT 
        t.c_customer_id,
        t.total_sales,
        RANK() OVER (ORDER BY t.total_sales DESC) AS sales_rank
    FROM 
        TotalSales t
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.sales_rank,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10 Sales'
        ELSE 'Other'
    END AS sales_category
FROM 
    RankedSales r
WHERE 
    r.total_sales IS NOT NULL
      AND r.sales_rank <= 50
ORDER BY 
    r.sales_rank;
