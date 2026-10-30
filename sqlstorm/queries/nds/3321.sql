
WITH recent_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
high_profit_items AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        rs.total_quantity,
        rs.total_profit
    FROM 
        item
    JOIN 
        recent_sales rs ON item.i_item_sk = rs.ws_item_sk
    WHERE
        rs.rank <= 10
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_paid) > 1000
)
SELECT 
    COALESCE(hpi.i_item_desc, 'N/A') AS item_description,
    COALESCE(tc.c_customer_id, 'N/A') AS customer_id,
    COALESCE(tc.total_spent, 0) AS customer_spent,
    hpi.total_quantity,
    hpi.total_profit
FROM 
    high_profit_items hpi
FULL OUTER JOIN 
    top_customers tc ON hpi.total_quantity > 0
ORDER BY 
    hpi.total_profit DESC NULLS LAST;
