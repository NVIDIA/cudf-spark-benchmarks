
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND ws.ws_sales_price > 100
    GROUP BY 
        w.w_warehouse_id, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.total_sales,
        s.total_orders,
        s.unique_customers
    FROM 
        customer c
    JOIN 
        sales_summary s ON c.c_first_name = s.c_first_name AND c.c_last_name = s.c_last_name
    WHERE 
        s.total_sales > 10000
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.total_orders,
    CASE 
        WHEN hvc.unique_customers > 10 THEN 'Loyal Customer'
        ELSE 'New Customer'
    END AS customer_status
FROM 
    high_value_customers hvc
ORDER BY 
    hvc.total_sales DESC
LIMIT 50;
