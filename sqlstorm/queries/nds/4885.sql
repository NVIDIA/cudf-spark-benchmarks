
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
),
Sales_Aggregates AS (
    SELECT 
        SUM(total_sales) AS total_revenue,
        COUNT(*) AS total_orders,
        AVG(order_count) AS avg_orders_per_customer
    FROM 
        Top_Customers
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    sa.total_revenue,
    sa.total_orders,
    sa.avg_orders_per_customer,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales > 1000 THEN 'High Value'
        ELSE 'Regular Customer'
    END AS customer_value_type,
    COALESCE((
        SELECT 
            COUNT(*)
        FROM 
            store_sales ss
        WHERE 
            ss.ss_customer_sk = tc.c_customer_sk
    ), 0) AS total_store_sales
FROM 
    Top_Customers tc
CROSS JOIN 
    Sales_Aggregates sa
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
