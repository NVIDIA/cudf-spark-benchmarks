
WITH TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ss.ss_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ss.ss_net_profit) > 1000
), 
RecentReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
)
SELECT 
    tc.full_name,
    COALESCE(SUM(rr.total_returns), 0) AS return_count,
    COUNT(ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_profit) AS avg_order_value,
    SUM(tc.total_spent) AS total_spent
FROM 
    TopCustomers tc
LEFT JOIN 
    RecentReturns rr ON tc.c_customer_sk = rr.sr_item_sk
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk IS NOT NULL
    AND (ws.ws_sold_date_sk, ws.ws_item_sk) IN (
        SELECT 
            ws_sold_date_sk, 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_net_profit > 0
    )
GROUP BY 
    tc.full_name
ORDER BY 
    total_spent DESC
LIMIT 10;
