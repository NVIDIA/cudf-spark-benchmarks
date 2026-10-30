
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_transaction_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
RankedSales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.store_transaction_count,
        cs.web_transaction_count,
        RANK() OVER (ORDER BY (cs.total_store_sales + cs.total_web_sales) DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
),
TopSales AS (
    SELECT 
        r.customer_id,
        r.total_store_sales,
        r.total_web_sales,
        r.store_transaction_count,
        r.web_transaction_count
    FROM RankedSales r
    WHERE r.sales_rank <= 10
)
SELECT 
    t.customer_id,
    t.total_store_sales,
    t.total_web_sales,
    t.store_transaction_count,
    t.web_transaction_count,
    (t.total_store_sales + t.total_web_sales) AS grand_total,
    CASE 
        WHEN t.total_store_sales > t.total_web_sales THEN 'Store'
        WHEN t.total_web_sales > t.total_store_sales THEN 'Web'
        ELSE 'Equal'
    END AS preferred_channel
FROM TopSales t
ORDER BY grand_total DESC;
