
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
),
FrequentBuyers AS (
    SELECT 
        c.c_customer_id,
        COUNT(fb.ws_order_number) AS frequent_orders
    FROM 
        web_sales fb
    JOIN 
        customer c ON fb.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(fb.ws_order_number) > 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    fb.frequent_orders
FROM 
    TopCustomers tc
LEFT JOIN 
    FrequentBuyers fb ON tc.c_customer_id = fb.c_customer_id
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_sales DESC;
