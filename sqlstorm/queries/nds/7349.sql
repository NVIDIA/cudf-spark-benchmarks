WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458865 AND 2459521  
    GROUP BY 
        ws_item_sk
),
top_products AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tp.i_item_id, 
    tp.i_item_desc, 
    tp.total_quantity, 
    tp.total_sales, 
    cs.c_customer_id,
    cs.total_orders,
    cs.total_spent
FROM 
    top_products tp
CROSS JOIN 
    customer_stats cs
WHERE 
    tp.sales_rank <= 10  
ORDER BY 
    tp.total_sales DESC, 
    cs.total_spent DESC;