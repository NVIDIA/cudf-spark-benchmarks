
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        co.total_profit,
        co.order_count,
        co.avg_order_value,
        RANK() OVER (ORDER BY co.total_profit DESC) AS profit_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_customer_sk = c.c_customer_sk
    WHERE 
        co.total_profit > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.order_count,
    tc.avg_order_value
FROM 
    TopCustomers tc
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.total_profit DESC;
