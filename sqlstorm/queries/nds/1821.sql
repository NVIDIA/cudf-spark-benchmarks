WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
), 
high_value_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales,
        r.order_count
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 10
), 
avg_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales_value
    FROM 
        customer_sales
)
SELECT 
    hvc.c_first_name || ' ' || hvc.c_last_name AS customer_name,
    hvc.total_sales,
    hvc.order_count,
    CASE 
        WHEN hvc.total_sales > (SELECT avg_sales_value FROM avg_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance,
    COALESCE(NULLIF(hvc.order_count, 0), 1) AS adjusted_order_count 
FROM 
    high_value_customers hvc
ORDER BY 
    hvc.total_sales DESC;