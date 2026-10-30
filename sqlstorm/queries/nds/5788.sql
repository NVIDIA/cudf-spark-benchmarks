
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_revenue,
        AVG(ss.ss_ext_sales_price) AS average_sale_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_revenue,
        RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 5
),
SalesByDate AS (
    SELECT 
        d.d_date,
        SUM(ss.ss_ext_sales_price) AS daily_revenue
    FROM 
        store_sales ss 
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_revenue,
    sb.d_date,
    sb.daily_revenue
FROM 
    TopCustomers tc
JOIN 
    SalesByDate sb ON tc.total_revenue > (SELECT AVG(total_revenue) FROM TopCustomers)
ORDER BY 
    tc.revenue_rank, sb.d_date DESC
LIMIT 10;
