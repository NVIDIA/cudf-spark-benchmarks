
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
top_customers AS (
    SELECT 
        customer.*,
        RANK() OVER (PARTITION BY customer.d_month_seq ORDER BY customer.total_sales_amount DESC) AS sales_rank
    FROM 
        sales_summary customer
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_quantity_sold,
    t.total_sales_amount,
    t.total_orders,
    d.d_month_seq
FROM 
    top_customers t
JOIN 
    date_dim d ON t.d_month_seq = d.d_month_seq
WHERE 
    t.sales_rank <= 5
ORDER BY 
    d.d_month_seq, t.total_sales_amount DESC;
