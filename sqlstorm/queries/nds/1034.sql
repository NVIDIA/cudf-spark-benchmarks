
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_ship_date_sk) AS last_order_date
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        cs.last_order_date,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
),
high_value_customers AS (
    SELECT 
        r.c_customer_sk,
        r.total_sales,
        r.order_count,
        r.last_order_date
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 100
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    d.d_date AS last_order_date
FROM 
    customer c
JOIN high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN date_dim d ON hvc.last_order_date = d.d_date_sk
WHERE 
    d.d_year = 2023
UNION ALL
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    0 AS total_sales,
    0 AS order_count,
    NULL AS last_order_date
FROM 
    customer c
WHERE 
    c.c_customer_sk NOT IN (SELECT hvc.c_customer_sk FROM high_value_customers hvc);
