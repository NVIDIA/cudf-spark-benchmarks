
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store Sales'
            WHEN total_web_sales > total_store_sales THEN 'Web Sales'
            ELSE 'Equal Sales'
        END AS sales_category,
        COUNT(*) AS number_of_customers,
        AVG(total_store_sales) AS avg_store_sales,
        AVG(total_web_sales) AS avg_web_sales
    FROM 
        CustomerSales
    GROUP BY 
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store Sales'
            WHEN total_web_sales > total_store_sales THEN 'Web Sales'
            ELSE 'Equal Sales'
        END
)
SELECT 
    sales_category,
    number_of_customers,
    avg_store_sales,
    avg_web_sales,
    ROW_NUMBER() OVER (ORDER BY number_of_customers DESC) AS rank
FROM 
    SalesSummary
ORDER BY 
    rank;
