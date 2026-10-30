
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
        JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
AverageSales AS (
    SELECT 
        AVG(total_profit) AS avg_profit,
        AVG(total_orders) AS avg_orders
    FROM 
        CustomerSales
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.total_orders,
    av.avg_profit,
    av.avg_orders
FROM 
    TopCustomers tc
    CROSS JOIN AverageSales av
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.total_profit DESC;
