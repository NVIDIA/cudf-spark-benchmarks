
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS total_store_transactions,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS total_web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        CASE 
            WHEN cs.total_store_sales > cs.total_web_sales THEN 'Store'
            WHEN cs.total_store_sales < cs.total_web_sales THEN 'Web'
            ELSE 'Equal'
        END AS preferred_channel,
        RANK() OVER (ORDER BY cs.total_store_sales + cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.total_store_sales,
    s.total_web_sales,
    s.preferred_channel,
    s.sales_rank,
    ROW_NUMBER() OVER (PARTITION BY s.preferred_channel ORDER BY s.sales_rank) AS channel_rank
FROM 
    SalesStatistics s
WHERE 
    s.total_store_sales > 0 OR s.total_web_sales > 0
ORDER BY 
    s.sales_rank;
