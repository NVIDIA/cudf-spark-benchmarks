
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        s.ss_sold_date_sk,
        SUM(s.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_net_profit) DESC) AS rn
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, s.ss_sold_date_sk
), 
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS monthly_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        date_dim d
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN 
        customer c ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        d.d_year, d.d_month_seq
), 
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ss.ss_net_profit) > 10000
)
SELECT 
    h.c_first_name || ' ' || h.c_last_name AS customer_name,
    m.d_year,
    m.d_month_seq,
    m.monthly_profit,
    COALESCE(b.total_profit, 0) AS total_hierarchical_profit
FROM 
    top_customers h
JOIN 
    monthly_sales m ON h.customer_rank <= 10
LEFT JOIN 
    sales_hierarchy b ON h.c_customer_sk = b.c_customer_sk AND b.rn = 1
ORDER BY 
    m.d_year DESC, m.d_month_seq DESC, total_hierarchical_profit DESC;
