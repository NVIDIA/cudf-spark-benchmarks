
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                customer_sales
            WHERE 
                sales_rank = 1
        )
)

SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    COALESCE(CASE 
        WHEN hvc.order_count > 10 THEN 'Frequent' 
        ELSE 'Occasional' 
    END, 'Unknown') AS customer_type,
    RANK() OVER (ORDER BY hvc.total_sales DESC) AS rank_by_sales,
    CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS full_name
FROM 
    high_value_customers hvc
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
