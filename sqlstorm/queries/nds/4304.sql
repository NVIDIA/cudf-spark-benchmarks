WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS annual_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.total_orders,
    ss.annual_sales,
    ss.avg_order_value
FROM 
    top_customers tc
LEFT JOIN 
    sales_summary ss ON ss.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) 
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.total_profit DESC;