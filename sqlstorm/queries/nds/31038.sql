
WITH  sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ts.total_sales,
        ts.total_orders
    FROM 
        sales_summary ts
    JOIN 
        customer c ON ts.c_customer_id = c.c_customer_id
    WHERE 
        ts.sales_rank <= 10
),
sales_with_page AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
final_report AS (
    SELECT 
        tc.c_customer_id,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.total_orders,
        COALESCE(swp.total_web_sales, 0) AS total_web_sales,
        COALESCE(swp.total_web_orders, 0) AS total_web_orders,
        tc.total_sales - COALESCE(swp.total_web_sales, 0) AS in_store_sales
    FROM 
        top_customers tc
    LEFT JOIN 
        sales_with_page swp ON tc.c_customer_id = swp.c_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.total_sales,
    fr.total_orders,
    fr.total_web_sales,
    fr.total_web_orders,
    fr.in_store_sales,
    CASE 
        WHEN fr.total_sales > 10000 THEN 'High Value'
        WHEN fr.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segmentation
FROM 
    final_report fr
ORDER BY 
    fr.total_sales DESC;
