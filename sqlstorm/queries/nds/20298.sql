
WITH categorized_sales AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_ship_date_sk >= 2459214 
    GROUP BY 
        ws.ws_item_sk
),
customer_activity AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk
),
profit_summary AS (
    SELECT 
        i.i_item_id,
        cs.total_orders,
        cs.total_quantity,
        cs.avg_profit,
        ca.purchase_count,
        ca.total_spent
    FROM 
        categorized_sales cs
    JOIN 
        item i ON cs.ws_item_sk = i.i_item_sk
    JOIN 
        customer_activity ca ON ca.purchase_count > 5
)
SELECT 
    ps.i_item_id,
    ps.total_orders,
    ps.total_quantity,
    COALESCE(ps.avg_profit, 0) AS avg_profit,
    CASE 
        WHEN ps.total_spent IS NULL THEN 'No Activity'
        WHEN ps.total_spent > 1000 THEN 'High Roller'
        ELSE 'Casual Shopper'
    END AS customer_type
FROM 
    profit_summary ps
LEFT JOIN 
    customer_demographics cd ON ps.purchase_count = cd.cd_dep_count
WHERE 
    (ps.total_orders >= 10 AND cd.cd_gender = 'M') OR (ps.total_orders < 10 AND cd.cd_gender IS NULL)
ORDER BY 
    ps.total_quantity DESC, ps.avg_profit DESC
LIMIT 50;
