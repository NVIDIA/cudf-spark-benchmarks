
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        COUNT(ws.ws_order_number) > 0
), 
ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        top_customers
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.order_count,
    rc.total_profit,
    coalesce(SUM(sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(ws.ws_net_paid), 0) - COALESCE(SUM(sr_return_amt), 0) AS net_sales
FROM 
    ranked_customers AS rc
LEFT JOIN 
    store_returns AS sr ON rc.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_sales AS ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    rc.profit_rank <= 10
GROUP BY 
    rc.c_customer_sk, rc.c_first_name, rc.c_last_name, rc.order_count, rc.total_profit
ORDER BY 
    rc.total_profit DESC;
