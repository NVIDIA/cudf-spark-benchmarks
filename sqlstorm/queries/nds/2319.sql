
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_store_sales,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        (cs.store_transactions + cs.web_transactions) AS total_transactions,
        CASE 
            WHEN cs.total_store_sales > cs.total_web_sales THEN 'Store' 
            WHEN cs.total_web_sales > cs.total_store_sales THEN 'Web' 
            ELSE 'Equal' 
        END AS preferred_channel
    FROM 
        CustomerSales cs
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.total_transactions,
        cs.preferred_channel,
        ROW_NUMBER() OVER (PARTITION BY cs.preferred_channel ORDER BY cs.total_transactions DESC) AS rank
    FROM 
        SalesSummary cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_store_sales,
    tc.total_web_sales,
    tc.total_transactions,
    tc.preferred_channel
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.preferred_channel, tc.total_transactions DESC;
