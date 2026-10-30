WITH  top_customers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        SUM(ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name 
    HAVING 
        SUM(ss_net_paid) > 10000
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
daily_sales AS (
    SELECT 
        d.d_date AS sale_date, 
        SUM(ss.ss_net_paid) AS daily_total
    FROM 
        date_dim d
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_date
),
sales_windows AS (
    SELECT 
        sale_date, 
        daily_total,
        LAG(daily_total, 1, 0) OVER (ORDER BY sale_date) AS previous_day_total,
        LEAD(daily_total, 1, 0) OVER (ORDER BY sale_date) AS next_day_total,
        (daily_total - COALESCE(LAG(daily_total) OVER (ORDER BY sale_date), 0)) AS change_from_previous
    FROM 
        daily_sales
),
customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cs.order_count,
    cs.total_spent,
    dw.sale_date,
    dw.daily_total,
    dw.change_from_previous,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Sales' 
        WHEN cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales) THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS spending_status
FROM 
    top_customers cu
JOIN 
    customer_sales cs ON cu.c_customer_sk = cs.c_customer_sk
JOIN 
    sales_windows dw ON dw.sale_date = cast('2002-10-01' as date)
ORDER BY 
    cs.total_spent DESC, 
    dw.sale_date;