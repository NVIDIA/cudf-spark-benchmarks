
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_amount,
        AVG(ws_net_profit) AS average_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales_amount,
        ss.average_net_profit,
        ss.total_orders
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    ORDER BY 
        ss.total_sales_amount DESC
    LIMIT 10
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        COUNT(DISTINCT ws_order_number) > 5
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales_amount,
    ti.average_net_profit,
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders AS customer_orders,
    cs.total_spent
FROM 
    top_items ti
CROSS JOIN 
    customer_summary cs
ORDER BY 
    ti.total_sales_amount DESC, cs.total_spent DESC;
