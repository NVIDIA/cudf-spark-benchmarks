
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_profit,
        cs.total_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS top_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_profit > 1000
),
return_stats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_profit,
    tc.total_orders,
    rs.total_returns,
    rs.total_return_amt,
    CASE 
        WHEN rs.total_returns > 0 THEN 'Returned'
        ELSE 'No Returns'
    END AS return_status
FROM 
    top_customers tc
LEFT JOIN 
    return_stats rs ON tc.c_customer_id = rs.c_customer_id
WHERE 
    tc.top_rank <= 10
ORDER BY 
    tc.total_profit DESC;
