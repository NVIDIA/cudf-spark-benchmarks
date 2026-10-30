
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
SalesSummary AS (
    SELECT 
        COALESCE(cs.c_customer_sk, ss.c_customer_sk) AS customer_sk,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        (COALESCE(cs.total_web_orders, 0) + COALESCE(ss.total_store_orders, 0)) AS total_orders
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
)
SELECT 
    customer_sk,
    total_sales,
    total_orders,
    total_sales / NULLIF(total_orders, 0) AS avg_sale_per_order
FROM 
    SalesSummary
WHERE 
    total_sales > 0
ORDER BY 
    avg_sale_per_order DESC
LIMIT 10;
