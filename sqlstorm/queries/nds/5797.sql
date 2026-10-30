
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit_per_order
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
high_spending_customers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cs.total_web_orders,
        cs.total_spent,
        cs.avg_profit_per_order
    FROM 
        customer_summary cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > 5000
),
product_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_units_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
top_products AS (
    SELECT 
        p.i_item_id,
        ps.total_units_sold,
        ps.total_profit
    FROM 
        item p
    JOIN 
        product_sales ps ON p.i_item_sk = ps.ws_item_sk
    ORDER BY 
        ps.total_profit DESC
    LIMIT 10
)
SELECT 
    h.customer_id,
    tp.i_item_id,
    tp.total_units_sold,
    h.total_spent,
    h.avg_profit_per_order
FROM 
    high_spending_customers h
JOIN 
    top_products tp ON h.total_spent > 10000 AND tp.total_units_sold > 100
ORDER BY 
    h.total_spent DESC, tp.total_profit DESC;
