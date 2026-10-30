
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS customer_orders,
        SUM(ws.ws_net_paid) AS customer_spending
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    cs.customer_orders,
    cs.customer_spending
FROM 
    top_items ti
LEFT JOIN 
    customer_summary cs ON cs.customer_orders > 0
ORDER BY 
    ti.total_sales DESC;
