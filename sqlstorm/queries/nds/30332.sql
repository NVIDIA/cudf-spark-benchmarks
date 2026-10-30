
WITH  SalesByDay AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date BETWEEN '2000-01-01' AND '2001-12-31'
    GROUP BY 
        d.d_date
), 
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopDays AS (
    SELECT 
        sale_date,
        total_net_profit,
        total_orders
    FROM 
        SalesByDay
    WHERE 
        sales_rank <= 5
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.customer_rank <= 10
)
SELECT 
    td.sale_date,
    td.total_net_profit,
    td.total_orders,
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count
FROM 
    TopDays td
FULL OUTER JOIN 
    TopCustomers tc ON td.sale_date = DATE '2002-10-01'  
ORDER BY 
    td.total_net_profit DESC NULLS LAST, 
    tc.total_spent DESC NULLS LAST;
