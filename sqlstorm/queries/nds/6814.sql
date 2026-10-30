
WITH ranked_sales AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2458846 AND 2458900
    GROUP BY 
        cs_item_sk
), top_items AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        rs.total_quantity, 
        rs.total_net_profit
    FROM 
        ranked_sales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.profit_rank <= 10
), customer_stats AS (
    SELECT 
        c.c_customer_id, 
        COUNT(DISTINCT ws_order_number) AS order_count, 
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ti.i_item_id, 
    ti.i_item_desc, 
    cs.c_customer_id, 
    cs.order_count, 
    cs.total_spent
FROM 
    top_items ti
JOIN 
    customer_stats cs ON cs.order_count > 0
ORDER BY 
    ti.total_net_profit DESC, cs.total_spent DESC
LIMIT 20;
