
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
average_sales AS (
    SELECT 
        AVG(total_web_sales) AS avg_web_sales,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_sales
    WHERE 
        total_web_sales IS NOT NULL
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_web_sales,
    cs.total_orders,
    a.avg_web_sales,
    a.customer_count,
    CASE 
        WHEN cs.total_web_sales > a.avg_web_sales THEN 'Above Average'
        WHEN cs.total_web_sales < a.avg_web_sales THEN 'Below Average'
        ELSE 'Equal Average'
    END AS sales_comparison
FROM 
    top_customers cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
CROSS JOIN 
    average_sales a
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    cs.total_web_sales DESC;
