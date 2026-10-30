
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE((
        SELECT AVG(total_sales) 
        FROM TopCustomers 
        WHERE sales_rank <= 10
    ), 0) AS average_top_sales,
    COUNT(DISTINCT wp.wp_web_page_sk) AS unique_web_pages_visited
FROM 
    TopCustomers tc
LEFT JOIN 
    web_page wp ON wp.wp_customer_sk = tc.c_customer_sk
WHERE 
    tc.sales_rank <= 20
GROUP BY 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_sales, 
    tc.order_count
ORDER BY 
    tc.total_sales DESC
LIMIT 30;
