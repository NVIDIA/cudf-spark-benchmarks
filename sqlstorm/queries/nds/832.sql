
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        AVG(total_orders) AS avg_orders
    FROM 
        customer_sales
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    aa.avg_sales,
    aa.avg_orders,
    CASE 
        WHEN tc.total_sales > aa.avg_sales THEN 'Above Average'
        WHEN tc.total_sales < aa.avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_comparison
FROM 
    top_customers tc
CROSS JOIN 
    average_sales aa
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
