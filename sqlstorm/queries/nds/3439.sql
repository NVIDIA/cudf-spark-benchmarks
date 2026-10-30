
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_web_sales + total_store_sales DESC) AS sales_rank
    FROM CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS total_web_sales,
    COALESCE(tc.total_store_sales, 0) AS total_store_sales,
    tc.web_orders,
    tc.store_orders,
    CASE 
        WHEN (tc.total_web_sales IS NULL AND tc.total_store_sales IS NULL) THEN 'No Sales'
        WHEN (tc.total_web_sales IS NOT NULL AND tc.total_store_sales IS NULL) THEN 'Web Only'
        WHEN (tc.total_web_sales IS NULL AND tc.total_store_sales IS NOT NULL) THEN 'Store Only'
        ELSE 'Both Channels' 
    END AS Sales_Channel_Type
FROM TopCustomers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.sales_rank;
