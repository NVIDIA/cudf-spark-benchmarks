
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
MaxSales AS (
    SELECT 
        MAX(total_sales) AS max_sales
    FROM 
        TopCustomers
),
DateStats AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    ds.d_year,
    ds.total_orders,
    ds.total_revenue
FROM 
    TopCustomers tc
JOIN 
    MaxSales ms ON tc.total_sales = ms.max_sales
JOIN 
    DateStats ds ON ds.total_revenue > 1000000
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    ds.d_year, tc.total_sales DESC;
