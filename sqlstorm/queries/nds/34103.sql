
WITH  customer_orders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_items_sold,
        total_profit
    FROM 
        customer_orders
    WHERE 
        rank <= 10
),
product_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS product_rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
sales_summary AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        ps.i_item_desc,
        ps.total_quantity,
        ps.total_net_profit,
        CASE 
            WHEN ps.total_net_profit IS NULL THEN 'No Sales'
            ELSE CONCAT('Profit: $', ROUND(ps.total_net_profit, 2))
        END AS profit_statement
    FROM 
        top_customers tc
    LEFT JOIN 
        product_sales ps ON tc.c_customer_sk = ps.i_item_sk
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    COALESCE(s.i_item_desc, 'Unknown Product') AS i_item_desc,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    s.profit_statement
FROM 
    sales_summary s
ORDER BY 
    s.c_customer_sk, s.total_net_profit DESC;
