
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cte.c_customer_sk,
        cte.c_first_name,
        cte.c_last_name,
        cte.total_profit,
        RANK() OVER (ORDER BY cte.total_profit DESC) AS sales_rank
    FROM 
        CustomerSales AS cte
),
StoreSalesData AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales AS ss
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    tc.total_profit,
    ss.total_store_profit,
    ss.total_transactions,
    CASE 
        WHEN tc.total_profit > 1000 THEN 'High Roller'
        WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Budget Buyer'
    END AS customer_segment
FROM 
    TopCustomers AS tc
JOIN 
    StoreSalesData AS ss ON ss.ss_store_sk = (
        SELECT 
            s.s_store_sk
        FROM 
            store AS s
        WHERE 
            s.s_manager = (SELECT 
                               MAX(s_manager) 
                           FROM 
                               store)
        LIMIT 1
    )
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_profit DESC;
