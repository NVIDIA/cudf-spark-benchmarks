
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    INNER JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 0
),
high_value_customers AS (
    SELECT 
        t.c_customer_sk,
        t.c_first_name,
        t.c_last_name,
        t.total_sales
    FROM 
        top_customers t
    WHERE 
        t.sales_rank <= 10
)

SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    COALESCE(d.d_dow, 0) AS day_of_week,
    i.i_product_name,
    SUM(ws.ws_quantity) AS total_quantity_sold
FROM 
    high_value_customers hvc
LEFT JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name, hvc.total_sales, d.d_dow, i.i_product_name
ORDER BY 
    hvc.total_sales DESC, hvc.c_last_name ASC
LIMIT 20;
