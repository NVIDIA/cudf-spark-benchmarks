
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_web_sales + COALESCE(ss.total_store_sales, 0) AS grand_total_sales,
        cs.total_orders + COALESCE(ss.total_store_orders, 0) AS grand_total_orders
    FROM 
        CustomerSales AS cs
    LEFT JOIN 
        StoreSales AS ss ON cs.c_customer_sk = ss.c_customer_sk
),
SalesRanking AS (
    SELECT 
        c.c_customer_id,
        ts.grand_total_sales,
        ts.grand_total_orders,
        RANK() OVER (ORDER BY ts.grand_total_sales DESC) AS sales_rank
    FROM 
        TotalSales AS ts
    JOIN 
        customer AS c ON ts.c_customer_sk = c.c_customer_sk
)
SELECT 
    sr.c_customer_id,
    sr.grand_total_sales,
    sr.grand_total_orders,
    sr.sales_rank,
    CASE 
        WHEN sr.grand_total_sales IS NULL THEN 'No Sales'
        WHEN sr.grand_total_sales < 1000 THEN 'Low Sales'
        WHEN sr.grand_total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    SalesRanking AS sr
WHERE 
    sr.sales_rank <= 100
ORDER BY 
    sr.grand_total_sales DESC;
