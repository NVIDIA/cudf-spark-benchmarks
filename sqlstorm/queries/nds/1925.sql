
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
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
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales IS NOT NULL
),
SalesByDate AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_date
),
WeeklySales AS (
    SELECT 
        EXTRACT(WEEK FROM d_date) AS week_number,
        SUM(daily_sales) AS weekly_sales
    FROM 
        SalesByDate
    GROUP BY 
        week_number
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    (SELECT AVG(total_sales) FROM TopCustomers WHERE sales_rank <= 10) AS avg_top_sales,
    ws.weekly_sales
FROM 
    TopCustomers tc
JOIN 
    WeeklySales ws ON ws.week_number = EXTRACT(WEEK FROM DATE '2002-10-01')
WHERE 
    tc.sales_rank <= 50
ORDER BY 
    tc.total_sales DESC;
