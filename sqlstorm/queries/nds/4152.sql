
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_net_profit
    FROM 
        ranked_sales rs
    WHERE 
        rs.profit_rank <= 5
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ts.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        top_sales ts ON c.c_customer_sk = ts.ws_order_number
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_net_profit,
    CASE 
        WHEN cs.total_net_profit IS NULL THEN 'No Sales'
        WHEN cs.total_net_profit < 1000 THEN 'Low Profit'
        WHEN cs.total_net_profit BETWEEN 1000 AND 5000 THEN 'Medium Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    customer_sales cs
LEFT JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S')
ORDER BY 
    cs.total_net_profit DESC
LIMIT 10;
