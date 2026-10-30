
WITH  sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
        AND ws.ws_net_profit IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_profit
    FROM 
        sales_summary s
    WHERE 
        s.rank <= 10
),
return_info AS (
    SELECT 
        sr_item_sk,
        COUNT(*) as total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.total_return_value, 0) AS total_return_value,
    CASE 
        WHEN ri.total_return_value > 0 THEN (tc.total_profit - ri.total_return_value) 
        ELSE tc.total_profit 
    END AS profit_after_returns
FROM 
    top_customers tc
LEFT JOIN 
    return_info ri ON tc.c_customer_sk = ri.sr_item_sk
ORDER BY 
    profit_after_returns DESC;

