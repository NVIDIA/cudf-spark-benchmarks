
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        ss.s_store_sk,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        cs.web_order_count,
        ss.store_order_count
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
)
SELECT 
    SUM(web_sales) AS total_web_sales,
    SUM(store_sales) AS total_store_sales,
    AVG(web_order_count) AS avg_web_orders,
    AVG(store_order_count) AS avg_store_orders
FROM 
    SalesSummary
WHERE 
    web_sales > 1000 OR store_sales > 1000;
