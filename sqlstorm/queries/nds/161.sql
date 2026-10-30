WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_web_sales DESC) AS dense_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS total_web_sales,
    COALESCE(tc.total_orders, 0) AS total_orders,
    CASE 
        WHEN tc.dense_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS customer_rank
FROM 
    TopCustomers tc
WHERE 
    tc.dense_rank <= 10 OR tc.total_web_sales IS NOT NULL
ORDER BY 
    tc.total_web_sales DESC;