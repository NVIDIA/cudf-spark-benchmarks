
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity_sold,
        SUM(s.ss_net_profit) AS total_net_profit_sold,
        c.c_first_name,
        c.c_last_name
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE 
        s.ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        s.ss_item_sk, c.c_first_name, c.c_last_name
),
combined_sales AS (
    SELECT 
        si.i_item_id,
        COALESCE(ts.total_quantity_sold, 0) AS total_store_quantity,
        COALESCE(ts.total_net_profit_sold, 0) AS total_store_net_profit,
        COALESCE(ws.total_quantity, 0) AS total_web_quantity,
        COALESCE(ws.total_net_profit, 0) AS total_web_net_profit
    FROM 
        item si
    LEFT JOIN 
        sales_summary ws ON si.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        top_items ts ON si.i_item_sk = ts.ss_item_sk
)
SELECT 
    i_item_id,
    total_store_quantity,
    total_store_net_profit,
    total_web_quantity,
    total_web_net_profit,
    (total_store_net_profit + total_web_net_profit) AS overall_net_profit
FROM 
    combined_sales
WHERE 
    (total_store_net_profit + total_web_net_profit) > 1000
ORDER BY 
    overall_net_profit DESC
LIMIT 10;
