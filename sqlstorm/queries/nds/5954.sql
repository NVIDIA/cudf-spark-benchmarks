
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.total_purchases
    FROM 
        customer_sales cs
    WHERE 
        cs.total_profit > 1000 AND cs.total_purchases > 5
),
average_sales AS (
    SELECT 
        AVG(total_profit) AS avg_profit,
        AVG(total_purchases) AS avg_purchases
    FROM 
        high_value_customers
),
customer_percent AS (
    SELECT 
        hvc.c_customer_sk,
        (hvc.total_profit / a.avg_profit * 100) AS profit_percentage,
        (hvc.total_purchases / a.avg_purchases * 100) AS purchase_percentage
    FROM 
        high_value_customers hvc
    CROSS JOIN average_sales a
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    cp.profit_percentage,
    cp.purchase_percentage
FROM 
    high_value_customers hvc
JOIN 
    customer_percent cp ON hvc.c_customer_sk = cp.c_customer_sk
ORDER BY 
    cp.profit_percentage DESC, cp.purchase_percentage DESC;
