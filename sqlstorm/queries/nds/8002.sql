WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.sales_rank <= 10
),
SalesByDate AS (
    SELECT 
        dd.d_date AS sales_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date
),
OverallStatistics AS (
    SELECT 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales ws
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    sbd.sales_date,
    sbd.daily_sales,
    os.total_orders,
    os.total_revenue
FROM 
    TopCustomers tc
JOIN 
    SalesByDate sbd ON DATE_PART('month', sbd.sales_date) = DATE_PART('month', cast('2002-10-01' as date))
JOIN 
    OverallStatistics os ON TRUE
ORDER BY 
    tc.total_sales DESC, sbd.sales_date DESC;