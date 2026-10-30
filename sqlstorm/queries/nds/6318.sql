
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        s.s_store_id
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        ss.total_store_sales,
        COALESCE(cs.total_orders, 0) AS total_orders,
        COALESCE(ss.total_transactions, 0) AS total_transactions
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.s_store_id
)
SELECT 
    COALESCE(total_web_sales, 0) AS web_sales,
    COALESCE(total_store_sales, 0) AS store_sales,
    total_orders,
    total_transactions,
    (COALESCE(total_web_sales, 0) + COALESCE(total_store_sales, 0)) AS combined_sales
FROM 
    SalesSummary
ORDER BY 
    combined_sales DESC
LIMIT 100;
