
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= 2459439 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk < 2459439
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
)

, high_profit_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1960 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        COALESCE(SUM(ws.ws_net_profit), 0) > 1000
), 
ranked_customers AS (
    SELECT 
        h.full_name,
        h.total_sales_profit,
        RANK() OVER (ORDER BY h.total_sales_profit DESC) AS profit_rank
    FROM 
        high_profit_customers h
)

SELECT 
    r.full_name,
    r.total_sales_profit,
    DENSE_RANK() OVER (ORDER BY r.total_sales_profit DESC) AS dense_rank,
    CASE 
        WHEN r.total_sales_profit IS NULL THEN 'No profit' 
        ELSE 'Profitable' 
    END AS profit_status
FROM 
    ranked_customers r
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.total_sales_profit DESC;
