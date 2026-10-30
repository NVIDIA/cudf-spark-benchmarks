
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_online_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_order_count
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
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
CombinedSales AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_online_sales, 0) AS total_online_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_online_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS overall_total_sales,
        (SELECT COUNT(DISTINCT s.s_store_id) FROM store s) AS total_stores
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.c_customer_id
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_online_sales,
    cs.total_store_sales,
    cs.overall_total_sales,
    CASE 
        WHEN cs.overall_total_sales = 0 THEN 'No Sales'
        WHEN cs.overall_total_sales BETWEEN 1 AND 100 THEN 'Low Sales'
        WHEN cs.overall_total_sales BETWEEN 101 AND 1000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category,
    (SELECT 
        AVG(total_online_sales) 
     FROM 
        CombinedSales) AS average_online_sales,
    (SELECT 
        AVG(total_store_sales) 
     FROM 
        CombinedSales) AS average_store_sales
FROM 
    CombinedSales cs
LEFT JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
ORDER BY 
    cs.overall_total_sales DESC;
