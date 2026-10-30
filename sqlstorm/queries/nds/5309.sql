
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_closed_date_sk IS NULL
    GROUP BY 
        s.s_store_id
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        cs.order_count,
        ss.transaction_count
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.s_store_id
)
SELECT 
    SUM(total_web_sales) AS overall_web_sales,
    SUM(total_store_sales) AS overall_store_sales,
    AVG(order_count) AS average_order_count,
    AVG(transaction_count) AS average_transaction_count
FROM 
    SalesSummary
WHERE 
    (total_web_sales > 0 OR total_store_sales > 0);
