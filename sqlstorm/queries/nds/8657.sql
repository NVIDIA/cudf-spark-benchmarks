WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990 
    GROUP BY 
        c.c_customer_sk
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_net_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_net_profit,
    tc.total_orders
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
WHERE 
    tc.profit_rank <= 10 
ORDER BY 
    tc.total_net_profit DESC;