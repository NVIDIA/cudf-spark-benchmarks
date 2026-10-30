
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_ship_date_sk) AS last_order_date_sk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity,
        cs.total_sales,
        cs.total_orders,
        cs.last_order_date_sk,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > 1000
),
sales_summary AS (
    SELECT 
        td.d_year,
        SUM(t.total_sales) AS yearly_sales,
        COUNT(DISTINCT t.c_customer_id) AS unique_customers
    FROM 
        date_dim td
    JOIN 
        top_customers t ON td.d_date_sk = t.last_order_date_sk
    GROUP BY 
        td.d_year
)
SELECT 
    t.yearly_sales,
    t.unique_customers,
    COALESCE(t.yearly_sales / NULLIF(t.unique_customers, 0), 0) AS avg_sales_per_customer
FROM 
    sales_summary t
ORDER BY 
    t.yearly_sales DESC
LIMIT 10;
