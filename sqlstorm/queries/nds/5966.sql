
WITH sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_sales_price) AS total_sales_amount,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        AVG(cs_sales_price) AS average_sales_price
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
top_items AS (
    SELECT 
        cs_item_sk AS ss_item_sk,
        total_quantity_sold,
        total_sales_amount,
        total_orders,
        average_sales_price
    FROM 
        sales_summary
    ORDER BY 
        total_sales_amount DESC
    LIMIT 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_spent,
        c.total_orders
    FROM 
        customer_info c
    ORDER BY 
        c.total_spent DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    ti.total_quantity_sold,
    ti.total_sales_amount,
    ti.total_orders,
    ti.average_sales_price
FROM 
    top_customers tc
JOIN 
    top_items ti ON tc.total_orders > 5
ORDER BY 
    tc.total_spent DESC, ti.total_sales_amount DESC;
