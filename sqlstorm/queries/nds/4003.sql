
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_web_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    CASE 
        WHEN tc.total_web_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Achieved'
    END AS sales_status,
    (SELECT 
        COUNT(DISTINCT ws.ws_order_number)
     FROM 
        web_sales ws
     WHERE 
        ws.ws_bill_customer_sk = tc.c_customer_sk AND 
        ws.ws_sales_price >= 50) AS high_value_orders
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_web_sales DESC;
