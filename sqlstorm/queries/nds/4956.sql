WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        *
    FROM 
        CustomerSales
    WHERE 
        sales_rank <= 10
), 
StoreStats AS (
    SELECT 
        s.s_store_id,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_country = 'USA'
    GROUP BY 
        s.s_store_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    ss.s_store_id,
    ss.avg_profit,
    ss.total_sales
FROM 
    TopCustomers tc
LEFT JOIN 
    StoreStats ss ON ss.total_sales > 0 
WHERE 
    tc.total_profit > (SELECT AVG(total_profit) FROM CustomerSales) 
ORDER BY 
    tc.total_profit DESC, 
    ss.avg_profit DESC;