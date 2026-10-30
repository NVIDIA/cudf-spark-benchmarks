
WITH sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS total_orders, 
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c_customer_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk, 
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    ci.c_customer_sk, 
    ci.total_orders, 
    ci.total_spent, 
    ti.i_item_desc, 
    ti.total_quantity, 
    ti.total_sales
FROM 
    customer_summary ci
CROSS JOIN 
    top_items ti
WHERE 
    ci.total_spent > 1000
ORDER BY 
    ci.total_spent DESC, 
    ti.total_sales DESC;
