
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_orders, 
        cs.total_sales,
        cs.avg_order_value
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
),
item_sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT
        isum.ws_item_sk,
        i.i_item_desc,
        isum.total_sold,
        isum.total_revenue,
        ROW_NUMBER() OVER (ORDER BY isum.total_revenue DESC) AS item_rank
    FROM 
        item_sales_summary isum
    JOIN 
        item i ON isum.ws_item_sk = i.i_item_sk
    WHERE 
        isum.total_sold > 0
)
SELECT 
    hvc.c_customer_id, 
    hvc.total_orders, 
    hvc.total_sales,
    ti.i_item_desc,
    ti.total_sold,
    ti.total_revenue
FROM 
    high_value_customers hvc
LEFT JOIN 
    top_items ti ON hvc.total_orders > 5 AND ti.item_rank <= 10
WHERE 
    hvc.avg_order_value IS NOT NULL
ORDER BY 
    hvc.total_sales DESC, 
    ti.total_revenue DESC;
