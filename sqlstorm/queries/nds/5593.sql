
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                   AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS rnk
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.total_orders,
    d.d_month_seq,
    d.d_year
FROM TopCustomers tc
JOIN date_dim d ON d.d_date_sk IN (
    SELECT d_date_sk FROM date_dim
    WHERE d_year = '2023' AND d_month_seq IN (1, 2, 3) 
)
WHERE tc.rnk <= 10
ORDER BY tc.total_profit DESC;
