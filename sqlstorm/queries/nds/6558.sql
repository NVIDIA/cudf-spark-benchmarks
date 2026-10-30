
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
    JOIN 
        (SELECT DISTINCT c_customer_sk, c_first_name, c_last_name FROM customer) c 
        ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders
FROM 
    TopCustomers tc
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
