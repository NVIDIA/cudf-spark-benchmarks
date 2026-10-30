
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit
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
        cs.order_count,
        cs.total_net_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_net_profit DESC) as rank
    FROM 
        CustomerSales cs
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    tc.order_count,
    tc.total_net_profit
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.rank <= 10 
    AND ca.ca_state IS NOT NULL
ORDER BY 
    tc.total_net_profit DESC;
