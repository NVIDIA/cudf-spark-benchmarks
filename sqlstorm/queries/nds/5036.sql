
WITH TotalSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
SalesRanks AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        TotalSales
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_orders
    FROM 
        SalesRanks
    WHERE 
        sales_rank <= 100
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    tc.total_orders
FROM 
    customer c
JOIN 
    TopCustomers tc ON c.c_customer_id = tc.c_customer_id
ORDER BY 
    tc.total_sales DESC;
