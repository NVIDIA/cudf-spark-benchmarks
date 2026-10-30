
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
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
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) AS grand_total_sales,
        cs.total_orders,
        COALESCE(ss.store_orders, 0) AS total_store_orders
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.grand_total_sales,
    t.total_orders,
    t.total_store_orders,
    CASE 
        WHEN t.grand_total_sales IS NULL THEN 'No Sales'
        WHEN t.grand_total_sales >= 10000 THEN 'High Value Customer'
        WHEN t.grand_total_sales BETWEEN 5000 AND 9999 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    TotalSales t
WHERE 
    t.grand_total_sales IS NOT NULL OR t.total_orders > 0
ORDER BY 
    t.grand_total_sales DESC;
