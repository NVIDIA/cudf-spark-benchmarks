WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
), StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
), CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.total_orders,
        ss.s_store_sk,
        ss.total_store_sales,
        ss.total_store_orders
    FROM 
        CustomerSales cs
    JOIN 
        store s ON cs.c_customer_sk = s.s_store_sk 
    JOIN 
        StoreSales ss ON s.s_store_sk = ss.s_store_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_web_sales,
    cs.total_orders,
    ss.total_store_sales,
    ss.total_store_orders,
    (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
    (COALESCE(cs.total_orders, 0) + COALESCE(ss.total_store_orders, 0)) AS total_orders_count
FROM 
    CombinedSales cs
LEFT JOIN 
    StoreSales ss ON cs.s_store_sk = ss.s_store_sk
ORDER BY 
    total_sales DESC
LIMIT 10;