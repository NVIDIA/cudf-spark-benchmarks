
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_order_quantity
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
item_summary AS (
    SELECT 
        i.i_item_id,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
most_purchased_items AS (
    SELECT 
        item_summary.i_item_id,
        item_summary.order_count,
        item_summary.total_profit,
        RANK() OVER (ORDER BY item_summary.order_count DESC) AS rank_order
    FROM 
        item_summary
)
SELECT 
    cs.c_customer_id,
    cs.total_spent,
    cs.total_orders,
    cs.avg_order_quantity,
    mpi.i_item_id,
    mpi.order_count,
    mpi.total_profit
FROM 
    customer_summary cs
JOIN 
    most_purchased_items mpi ON cs.total_orders > 5
WHERE 
    mpi.rank_order <= 10
ORDER BY 
    cs.total_spent DESC, 
    mpi.order_count DESC;
