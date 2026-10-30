
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cus.c_customer_id,
        cus.c_first_name,
        cus.c_last_name,
        cs.total_spent,
        cs.total_orders,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer cus ON cs.c_customer_sk = cus.c_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    tc.avg_order_value
FROM 
    TopCustomers tc
WHERE 
    tc.spend_rank <= 10
ORDER BY 
    tc.total_spent DESC;

