WITH ranked_sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_net_profit
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.cs_item_sk = i.i_item_sk
    WHERE 
        r.profit_rank <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30  
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        customer_sales.c_customer_id,
        customer_sales.order_count,
        customer_sales.total_spent,
        RANK() OVER (ORDER BY customer_sales.total_spent DESC) AS customer_rank
    FROM 
        customer_sales
)
SELECT 
    tc.c_customer_id,
    tc.order_count,
    tc.total_spent,
    ti.i_item_id,
    ti.i_item_desc
FROM 
    top_customers tc
JOIN 
    top_items ti ON tc.order_count > 5
WHERE 
    tc.customer_rank <= 50
ORDER BY 
    tc.total_spent DESC, 
    tc.order_count DESC;