
WITH ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        cs.cs_item_sk
),
top_items AS (
    SELECT 
        r.cs_item_sk,
        i.i_item_desc,
        r.total_net_profit
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.cs_item_sk = i.i_item_sk
    WHERE 
        r.profit_rank <= 5
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ts.i_item_desc,
    cs.c_customer_id,
    cs.total_orders,
    cs.total_spent,
    cs.last_order_date
FROM 
    top_items ts
CROSS JOIN 
    customer_summary cs
WHERE 
    cs.total_spent > 1000
ORDER BY 
    ts.total_net_profit DESC, cs.total_orders DESC
LIMIT 10;
