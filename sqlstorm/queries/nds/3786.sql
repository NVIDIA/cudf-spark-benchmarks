
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_web_orders,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        ss.total_store_orders
    FROM CustomerSales cs
    FULL OUTER JOIN StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
),
Ranking AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY (total_web_sales + total_store_sales) DESC) AS sales_rank
    FROM TotalSales
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(c.total_web_sales, 0) AS total_web_sales,
    COALESCE(c.total_store_sales, 0) AS total_store_sales,
    c.sales_rank,
    CASE 
        WHEN c.sales_rank <= 10 THEN 'Top 10 Customers'
        WHEN c.sales_rank <= 50 THEN 'Top 50 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM Ranking c
WHERE c.total_web_sales > 1000 OR c.total_store_sales > 1000
ORDER BY c.sales_rank;
