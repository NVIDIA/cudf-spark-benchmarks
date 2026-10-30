
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        SUM(total_store_sales) AS total_sales_store,
        SUM(total_web_sales) AS total_sales_web,
        AVG(store_transactions) AS avg_store_transactions,
        AVG(web_transactions) AS avg_web_transactions
    FROM 
        CustomerSales
)
SELECT 
    total_sales_store,
    total_sales_web,
    avg_store_transactions,
    avg_web_transactions,
    CASE 
        WHEN total_sales_store > total_sales_web THEN 'Store Sales Dominant'
        WHEN total_sales_web > total_sales_store THEN 'Web Sales Dominant'
        ELSE 'Equal Sales'
    END AS sales_strategy
FROM 
    SalesSummary;
