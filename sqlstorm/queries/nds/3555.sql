
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
        r.order_count,
        COALESCE(DENSE_RANK() OVER (PARTITION BY CASE WHEN r.total_sales > 10000 THEN 'High' ELSE 'Moderate' END 
            ORDER BY r.order_count DESC), 0) AS customer_rank
    FROM 
        ranked_sales r
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    h.order_count,
    h.customer_rank,
    CASE 
        WHEN h.customer_rank > 0 THEN 'Ranked Customer'
        ELSE 'Unranked Customer'
    END AS customer_status
FROM 
    high_value_customers h
WHERE 
    h.total_sales IS NOT NULL
ORDER BY 
    h.total_sales DESC, h.customer_rank;
