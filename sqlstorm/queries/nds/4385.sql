WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
SalesByDate AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_net_paid_inc_tax) AS daily_sales
    FROM date_dim dd
    LEFT JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY dd.d_date
),
SalesTrends AS (
    SELECT 
        d.d_date,
        daily_sales,
        LAG(daily_sales, 1, 0) OVER (ORDER BY d.d_date) AS prev_day_sales,
        (daily_sales - LAG(daily_sales, 1, 0) OVER (ORDER BY d.d_date)) AS sales_change
    FROM SalesByDate d
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    st.d_date,
    st.daily_sales,
    st.sales_change
FROM TopCustomers tc
JOIN SalesTrends st ON st.daily_sales > (SELECT AVG(daily_sales) FROM SalesByDate) 
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC, st.d_date DESC;