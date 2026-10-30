WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - 21)
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
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales IS NOT NULL
),
SalesSummary AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_daily_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim AS d 
    JOIN 
        web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)

SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.order_count,
    COALESCE(s.total_daily_sales, 0) AS total_sales_yesterday,
    COALESCE(s.total_orders, 0) AS total_orders_yesterday
FROM 
    TopCustomers AS t
LEFT JOIN 
    SalesSummary AS s ON s.d_date = cast('2002-10-01' as date) - INTERVAL '1 DAY'
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;