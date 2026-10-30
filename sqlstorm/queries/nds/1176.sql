
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    WHERE cs.total_sales >= (
        SELECT AVG(total_sales) 
        FROM CustomerSales
    )
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM store s
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY s.s_store_sk, s.s_store_name
    HAVING COUNT(DISTINCT ws.ws_order_number) > 100
),
FinalOutput AS (
    SELECT 
        hs.c_customer_sk,
        hs.c_first_name,
        hs.c_last_name,
        hs.total_sales,
        hs.order_count,
        ts.s_store_name,
        ts.total_orders,
        ts.total_profit
    FROM HighSpenders hs
    CROSS JOIN TopStores ts
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    COALESCE(f.total_sales, 0) AS total_sales,
    COALESCE(f.order_count, 0) AS order_count,
    f.s_store_name,
    COALESCE(f.total_orders, 0) AS total_orders,
    COALESCE(f.total_profit, 0) AS total_profit
FROM FinalOutput f
ORDER BY f.total_sales DESC, f.total_orders DESC
LIMIT 50;
