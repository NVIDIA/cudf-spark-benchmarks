
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS average_transaction_value
    FROM customer AS c
    JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY c.c_customer_id
),
SalesStatistics AS (
    SELECT 
        total_sales,
        total_transactions,
        average_transaction_value,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile,
        COUNT(*) OVER () AS total_customers
    FROM CustomerSales
),
TopSales AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.total_transactions,
        cs.average_transaction_value
    FROM CustomerSales cs
    JOIN (SELECT * FROM SalesStatistics WHERE sales_quartile = 1) stats ON cs.total_sales = stats.total_sales
    JOIN customer AS c ON c.c_customer_id = cs.c_customer_id
)
SELECT 
    ts.c_customer_id,
    ts.total_sales,
    ts.total_transactions,
    ts.average_transaction_value,
    RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
FROM TopSales ts
ORDER BY ts.total_sales DESC
LIMIT 10;
