
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    INNER JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
high_profit_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.total_profit
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_profit > (
        SELECT AVG(total_profit) FROM customer_sales
    )
),
return_stats AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_return_quantity) AS total_return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    hpc.c_first_name,
    hpc.c_last_name,
    hpc.total_profit AS customer_profit,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    COALESCE(rs.total_return_count, 0) AS total_return_count,
    CASE 
        WHEN rs.total_return_amt IS NOT NULL THEN 
            (hpc.total_profit - rs.total_return_amt) 
        ELSE 
            hpc.total_profit 
    END AS net_profit_after_returns
FROM 
    high_profit_customers hpc
LEFT JOIN 
    return_stats rs ON hpc.c_customer_sk = rs.wr_returning_customer_sk
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;
