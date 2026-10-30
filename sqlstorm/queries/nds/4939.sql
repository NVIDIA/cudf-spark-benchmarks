
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        cs.web_order_count,
        COALESCE(ss.store_order_count, 0) AS store_order_count
    FROM CustomerSales cs
    LEFT JOIN StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
),
SalesRanking AS (
    SELECT 
        c_customer_sk,
        total_web_sales,
        total_store_sales,
        web_order_count,
        store_order_count,
        RANK() OVER (ORDER BY (total_web_sales + total_store_sales) DESC) AS sales_rank
    FROM TotalSales
),
TopCustomers AS (
    SELECT 
        c_customer_sk,
        total_web_sales,
        total_store_sales,
        web_order_count,
        store_order_count,
        sales_rank
    FROM SalesRanking
    WHERE sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    CONCAT(tc.total_web_sales, ' (Web), ', tc.total_store_sales, ' (Store)') AS sales_summary,
    tc.web_order_count + tc.store_order_count AS total_orders,
    CASE 
        WHEN tc.total_web_sales IS NULL AND tc.total_store_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM TopCustomers tc
ORDER BY tc.sales_rank;
