
WITH  top_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
),
aggregated_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
high_value_customers AS (
    SELECT 
        a.c_customer_sk, 
        a.total_orders,
        a.total_spent,
        ROW_NUMBER() OVER (ORDER BY a.total_spent DESC) AS customer_rank
    FROM 
        aggregated_sales a
    WHERE 
        a.total_spent > (SELECT AVG(total_spent) FROM aggregated_sales)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(t.total_quantity, 0) AS total_web_sales,
    hvc.total_orders AS total_high_value_orders,
    hvc.total_spent AS total_high_value_spent,
    ms.total_profit AS total_monthly_profit
FROM 
    customer c
LEFT JOIN 
    top_sales t ON c.c_customer_sk = t.ws_item_sk
LEFT JOIN 
    high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN 
    monthly_sales ms ON ms.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
ORDER BY 
    c.c_first_name, c.c_last_name;
