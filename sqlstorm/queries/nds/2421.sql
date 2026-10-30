
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
sales_statistics AS (
    SELECT 
        c.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        COUNT(*) OVER () AS total_customers
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales IS NOT NULL
),
best_customers AS (
    SELECT 
        s.c_customer_sk,
        s.total_sales,
        s.order_count,
        s.sales_rank,
        ROUND(100.0 * s.order_count / NULLIF(s.total_customers, 0), 2) AS order_percentage
    FROM 
        sales_statistics s
    WHERE 
        s.sales_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    COALESCE(bc.total_sales, 0) AS total_sales,
    COALESCE(bc.order_count, 0) AS order_count,
    bc.order_percentage
FROM 
    best_customers bc
JOIN 
    customer c ON bc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    bc.total_sales DESC;
