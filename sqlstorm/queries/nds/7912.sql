
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_sk
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_store_orders
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY c.c_customer_sk
),
TotalSales AS (
    SELECT
        COALESCE(cu.c_customer_sk, st.c_customer_sk) AS customer_sk,
        COALESCE(cu.total_web_sales, 0) AS total_web_sales,
        COALESCE(cu.num_web_orders, 0) AS num_web_orders,
        COALESCE(st.total_store_sales, 0) AS total_store_sales,
        COALESCE(st.num_store_orders, 0) AS num_store_orders
    FROM CustomerSales cu
    FULL OUTER JOIN StoreSales st ON cu.c_customer_sk = st.c_customer_sk
),
SalesSummary AS (
    SELECT 
        customer_sk,
        total_web_sales,
        num_web_orders,
        total_store_sales,
        num_store_orders,
        (total_web_sales + total_store_sales) AS total_sales,
        (num_web_orders + num_store_orders) AS total_orders
    FROM TotalSales
)
SELECT 
    total_sales,
    total_orders,
    ROUND(CASE WHEN total_orders = 0 THEN 0 ELSE total_sales / total_orders END, 2) AS average_sales_per_order
FROM SalesSummary
WHERE total_sales > 10000
ORDER BY average_sales_per_order DESC
LIMIT 10;
