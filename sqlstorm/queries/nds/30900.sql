
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 1000
), 
ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        top_customers
), 
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales AS ws
    JOIN 
        ranked_customers AS rc ON ws.ws_bill_customer_sk = rc.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(i.i_current_price, 0) AS price,
    COALESCE(item_sales.total_quantity_sold, 0) AS quantity_sold,
    ROUND(COALESCE(item_sales.total_quantity_sold, 0) * COALESCE(i.i_current_price, 0), 2) AS total_revenue,
    rc.c_first_name,
    rc.c_last_name
FROM 
    item AS i
LEFT JOIN 
    item_sales ON i.i_item_sk = item_sales.ws_item_sk
JOIN 
    ranked_customers AS rc ON rc.total_profit IN (SELECT SUM(ws.ws_net_profit) 
                                                   FROM web_sales AS ws 
                                                   WHERE ws.ws_bill_customer_sk = rc.c_customer_sk)
WHERE 
    rc.profit_rank <= 10
ORDER BY 
    total_revenue DESC;
