WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit_per_order
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1985 
    GROUP BY 
        c.c_customer_id
),
SalesByDate AS (
    SELECT 
        dd.d_year,
        SUM(cs.total_sales) AS yearly_sales,
        AVG(cs.order_count) AS avg_orders
    FROM 
        date_dim dd
    JOIN 
        CustomerSales cs ON dd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        dd.d_year
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON c.c_customer_id = cs.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    (
        SELECT bd.yearly_sales
        FROM SalesByDate bd
        WHERE bd.d_year = (SELECT MAX(d_year) FROM SalesByDate)
    ) AS highest_yearly_sales,
    tc.sales_rank
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10;