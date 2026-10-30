
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 1000
),
date_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS yearly_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(ws.ws_order_number) AS orders_fulfilled,
        SUM(ws.ws_ext_sales_price) AS total_fulfillment_value
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    ds.d_year,
    ds.yearly_sales,
    wp.w_warehouse_id,
    wp.orders_fulfilled,
    wp.total_fulfillment_value
FROM 
    top_customers tc
JOIN 
    date_summary ds ON ds.yearly_sales > (SELECT AVG(yearly_sales) FROM date_summary)
JOIN 
    warehouse_performance wp ON wp.total_fulfillment_value > (SELECT AVG(total_fulfillment_value) FROM warehouse_performance)
ORDER BY 
    tc.sales_rank, ds.d_year;
