
WITH customer_sales AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c_first_name,
        c_last_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        customer_sales
),
sales_summary AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.rank,
        CASE 
            WHEN tc.rank <= 10 THEN 'Top 10 Customers'
            WHEN tc.rank <= 50 THEN 'Top 50 Customers'
            ELSE 'Other Customers'
        END AS category
    FROM 
        top_customers tc
)
SELECT 
    category,
    COUNT(*) AS customer_count,
    SUM(cs.total_spent) AS total_revenue
FROM 
    sales_summary s
JOIN 
    customer_sales cs ON s.c_first_name = cs.c_first_name AND s.c_last_name = cs.c_last_name
GROUP BY 
    category
ORDER BY 
    total_revenue DESC;
