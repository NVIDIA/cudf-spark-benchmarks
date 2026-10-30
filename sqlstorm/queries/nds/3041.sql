
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
customer_counts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        customer_counts cc ON ws.ws_bill_customer_sk = cc.c_customer_sk
    WHERE 
        cc.unique_customers IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ss.total_quantity,
    ss.total_profit,
    COALESCE(rs.profit_rank, 0) AS best_profit_rank
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    ranked_sales rs ON i.i_item_sk = rs.ws_item_sk AND rs.profit_rank = 1
WHERE 
    ss.total_profit > 0 AND 
    (i.i_current_price IS NOT NULL OR i.i_wholesale_cost IS NOT NULL)
ORDER BY 
    ss.total_profit DESC, 
    i.i_item_desc ASC;
