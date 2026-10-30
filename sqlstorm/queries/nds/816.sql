
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
store_sales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_web_sales > (SELECT AVG(total_web_sales) FROM customer_sales)
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    hvc.total_web_sales,
    hvc.order_count,
    CASE 
        WHEN hvc.total_web_sales > 1000 THEN 'High'
        WHEN hvc.total_web_sales > 500 THEN 'Medium'
        ELSE 'Low' 
    END AS customer_value
FROM 
    high_value_customers hvc
LEFT JOIN 
    store_sales ss ON hvc.c_customer_sk = ss.s_store_sk 
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_web_sales DESC;
