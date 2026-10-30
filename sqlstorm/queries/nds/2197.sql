
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450666
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM customer AS c
    JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450666
    GROUP BY c.c_customer_sk
),
SalesMix AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        CASE 
            WHEN COALESCE(ss.total_store_sales, 0) = 0 THEN 0 
            ELSE (cs.total_web_sales / (cs.total_web_sales + ss.total_store_sales)) * 100 
        END AS web_sales_percentage
    FROM CustomerSales cs
    LEFT JOIN StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
),
RankedSales AS (
    SELECT 
        sm.c_customer_sk,
        sm.total_web_sales,
        sm.total_store_sales,
        sm.web_sales_percentage,
        RANK() OVER (ORDER BY sm.web_sales_percentage DESC) AS sales_rank
    FROM SalesMix sm
)

SELECT 
    cs.c_first_name, 
    cs.c_last_name, 
    rs.total_web_sales, 
    rs.total_store_sales, 
    rs.web_sales_percentage,
    CASE 
        WHEN rs.web_sales_percentage >= 50 THEN 'High Web Usage' 
        ELSE 'Low Web Usage' 
    END AS usage_category
FROM RankedSales rs
JOIN customer AS cs ON rs.c_customer_sk = cs.c_customer_sk
WHERE rs.sales_rank <= 10
ORDER BY rs.web_sales_percentage DESC;
