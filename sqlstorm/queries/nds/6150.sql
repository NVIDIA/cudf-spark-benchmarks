
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_profit,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.avg_profit,
    ti.total_orders,
    cs.total_orders AS customer_order_count,
    cs.total_spent
FROM 
    top_items ti
LEFT JOIN 
    customer_summary cs ON ti.sales_rank <= 10
WHERE 
    cs.total_orders IS NOT NULL
ORDER BY 
    ti.total_sales DESC;
