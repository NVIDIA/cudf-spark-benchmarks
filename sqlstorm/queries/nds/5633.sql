WITH sales_summary AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS unique_shipping_methods
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 AND
        d.d_month_seq IN (1, 2, 3) 
    GROUP BY 
        c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c_first_name, 
        c_last_name, 
        total_sales,
        order_count,
        total_discount,
        total_tax,
        unique_shipping_methods,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2001 AND d.d_month_seq IN (1, 2, 3) 
        )
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.total_discount,
    tc.total_tax,
    tc.unique_shipping_methods,
    ws.w_warehouse_id,
    ws.total_items_sold
FROM 
    top_customers tc
JOIN 
    warehouse_summary ws ON tc.unique_shipping_methods > 2
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, 
    ws.total_items_sold DESC;