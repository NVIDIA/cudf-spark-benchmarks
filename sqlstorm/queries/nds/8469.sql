
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk
),
SalesBreakdown AS (
    SELECT 
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store'
            WHEN total_web_sales > total_store_sales THEN 'Web'
            ELSE 'Equal'
        END AS sales_preference,
        COUNT(*) AS customer_count,
        AVG(total_store_sales) AS avg_store_sales,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_store_transactions) AS avg_store_transactions,
        AVG(total_web_transactions) AS avg_web_transactions
    FROM 
        CustomerSales
    GROUP BY 
        sales_preference
)
SELECT 
    sales_preference,
    customer_count,
    avg_store_sales,
    avg_web_sales,
    avg_store_transactions,
    avg_web_transactions
FROM 
    SalesBreakdown
ORDER BY 
    customer_count DESC;
