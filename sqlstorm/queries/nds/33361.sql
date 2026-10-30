
WITH  sales_rank AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_ship_date_sk,
        ws_item_sk, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_returns AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_amt) AS total_return
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 10000
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    COUNT(DISTINCT sr.ws_item_sk) AS items_returned,
    COALESCE(cr.total_return, 0) AS total_returned_amount,
    SUM(sr.ws_net_profit) AS total_sales_profit,
    CASE 
        WHEN SUM(sr.ws_net_profit) > 1000 THEN 'High Value'
        ELSE 'Standard'
    END AS customer_segment
FROM 
    high_value_customers c
LEFT JOIN 
    sales_rank sr ON c.c_customer_sk = sr.ws_bill_customer_sk AND sr.rank <= 5
LEFT JOIN 
    customer_returns cr ON cr.wr_returning_customer_sk = c.c_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name, cr.total_return
ORDER BY 
    total_sales_profit DESC, customer_name
LIMIT 50;
