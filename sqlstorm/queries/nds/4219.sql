
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
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
),
store_sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    COALESCE(ss.total_store_sales, 0) AS store_sales,
    ss.total_transactions,
    CASE 
        WHEN hvc.total_sales > 10000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type
FROM 
    high_value_customers hvc
LEFT JOIN 
    store_sales_summary ss ON hvc.c_customer_sk = ss.s_store_sk
ORDER BY 
    hvc.sales_rank;
