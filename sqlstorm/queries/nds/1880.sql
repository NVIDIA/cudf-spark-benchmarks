
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        cs.sales_rank
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'S' 
        AND cs.total_sales > (
            SELECT AVG(total_sales) 
            FROM CustomerSales 
            WHERE total_sales IS NOT NULL
        )
)
SELECT 
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
    tc.total_sales,
    tc.total_orders,
    COALESCE((SELECT SUM(sr_return_amt) 
               FROM store_returns sr 
               WHERE sr.sr_customer_sk = tc.c_customer_sk), 0) AS total_return_amt
FROM TopCustomers tc
ORDER BY tc.total_sales DESC
LIMIT 10;
