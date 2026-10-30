WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN 2451545 AND 2451546 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.order_count > 0
),
StoreStats AS (
    SELECT 
        s.s_store_sk,
        COUNT(ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2451545 AND 2451546
    GROUP BY 
        s.s_store_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    ss.total_sales,
    ss.avg_net_profit,
    COALESCE(ss.avg_net_profit, 0) AS safe_avg_profit,
    CASE 
        WHEN tc.total_net_profit > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    TopCustomers tc
LEFT JOIN 
    StoreStats ss ON tc.c_customer_sk = ss.s_store_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC;