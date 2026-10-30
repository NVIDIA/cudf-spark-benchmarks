
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_month = 10 AND c.c_birth_day BETWEEN 1 AND 31
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        store s 
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
SalesComparison AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        ss.total_store_sales,
        COALESCE(cs.total_web_sales, 0) - COALESCE(ss.total_store_sales, 0) AS sales_difference
    FROM 
        CustomerSales cs
    LEFT JOIN 
        StoreSales ss ON cs.c_customer_sk IS NOT NULL
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    sales_difference,
    ROW_NUMBER() OVER (ORDER BY sales_difference DESC) AS ranking
FROM 
    SalesComparison c
LEFT JOIN 
    CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    StoreSales ss ON cs.c_customer_sk IS NOT NULL
WHERE 
    sales_difference > 0
ORDER BY 
    ranking
LIMIT 10;
