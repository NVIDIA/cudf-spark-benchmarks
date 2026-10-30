
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sd.ss_sold_date_sk,
        SUM(sd.ss_quantity) AS total_sales_quantity,
        SUM(sd.ss_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(sd.ss_net_profit) DESC) AS rank
    FROM customer c
    JOIN store_sales sd ON c.c_customer_sk = sd.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, sd.ss_sold_date_sk
),
avg_sales AS (
    SELECT 
        c_customer_sk,
        AVG(total_net_profit) AS avg_net_profit
    FROM sales_hierarchy
    WHERE rank = 1
    GROUP BY c_customer_sk
),
high_value_customers AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_sales_quantity,
        s.total_net_profit,
        a.avg_net_profit
    FROM sales_hierarchy s
    JOIN avg_sales a ON s.c_customer_sk = a.c_customer_sk
    WHERE s.total_net_profit > a.avg_net_profit
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales_profit
FROM high_value_customers c
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY c.c_first_name, c.c_last_name
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_sales_profit DESC
LIMIT 10;
