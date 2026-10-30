
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 1000 
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.order_count,
    t.last_purchase_date,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    top_customers t
JOIN 
    customer_address ca ON t.c_customer_sk = ca.ca_address_sk
ORDER BY 
    t.total_sales DESC;
