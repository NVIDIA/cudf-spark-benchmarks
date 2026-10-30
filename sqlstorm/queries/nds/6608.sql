
WITH CustomerWebSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cws.c_customer_id,
        cws.total_net_paid,
        cws.total_orders,
        cws.avg_order_value,
        RANK() OVER (ORDER BY cws.total_net_paid DESC) AS rank
    FROM 
        CustomerWebSales cws
)
SELECT 
    tc.c_customer_id,
    tc.total_net_paid,
    tc.total_orders,
    tc.avg_order_value
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_paid DESC;
