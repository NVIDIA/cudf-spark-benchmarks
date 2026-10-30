WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451370 AND 2451375  
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_net_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.c_email_address,
    tc.total_net_profit,
    tc.total_orders
FROM 
    TopCustomers tc
JOIN 
    customer cu ON tc.c_customer_sk = cu.c_customer_sk
WHERE 
    tc.rank <= 10  
ORDER BY 
    tc.total_net_profit DESC;