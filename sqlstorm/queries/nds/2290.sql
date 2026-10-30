
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
return_stats AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
active_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(tc.total_net_profit, 0) AS total_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.avg_return_quantity, 0) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        top_customers tc ON c.c_customer_sk = tc.c_customer_sk
    LEFT JOIN 
        return_stats rs ON c.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    ac.c_customer_sk,
    ac.c_first_name,
    ac.c_last_name,
    ac.total_net_profit,
    ac.total_returns,
    ac.total_return_amount,
    ac.avg_return_quantity,
    CASE
        WHEN ac.total_net_profit > 5000 THEN 'High Value'
        WHEN ac.total_net_profit BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ROW_NUMBER() OVER (ORDER BY ac.total_net_profit DESC) AS customer_rank
FROM 
    active_customers ac
ORDER BY 
    ac.total_net_profit DESC
LIMIT 10;
