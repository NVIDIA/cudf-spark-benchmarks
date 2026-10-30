
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        CustomerSales cs
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit AS customer_profit,
    si.s_store_name,
    si.total_store_profit,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    TopCustomers tc
JOIN 
    StoreInfo si ON si.total_store_profit > (SELECT AVG(total_store_profit) FROM StoreInfo)
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.sr_customer_sk = tc.c_customer_sk 
        AND sr.sr_return_quantity > 0
    )
ORDER BY 
    tc.total_profit DESC;
