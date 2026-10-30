
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c_sales.c_customer_id,
        c_sales.total_sales,
        c_sales.order_count
    FROM 
        customer_sales c_sales
    WHERE 
        c_sales.sales_rank <= 10
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales_amount
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
sales_summary AS (
    SELECT 
        ts.c_customer_id,
        ts.total_sales,
        COALESCE(ws.warehouse_sales_amount, 0) AS warehouse_amount,
        (ts.total_sales - COALESCE(ws.warehouse_sales_amount, 0)) AS net_amount
    FROM 
        top_customers ts
    LEFT JOIN 
        warehouse_sales ws ON ts.total_sales > 0
)
SELECT 
    s.c_customer_id,
    s.total_sales,
    s.warehouse_amount,
    s.net_amount,
    CASE 
        WHEN s.net_amount > 1000 THEN 'High'
        WHEN s.net_amount BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    CASE 
        WHEN s.warehouse_amount IS NULL THEN 'No Sales'
        WHEN s.warehouse_amount < 100 THEN 'Minor Warehouse Sales'
        ELSE 'Significant Warehouse Sales'
    END AS warehouse_category
FROM 
    sales_summary s
ORDER BY 
    s.total_sales DESC;
