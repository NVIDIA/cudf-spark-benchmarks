WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458593 AND 2458650 
    GROUP BY 
        ws.ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS rank
    FROM 
        sales_data sd
    WHERE 
        sd.total_quantity > 100
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        customer_stats cs
    WHERE 
        cs.total_profit > 5000
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_profit,
    tc.c_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_profit
FROM 
    top_items ti
FULL OUTER JOIN 
    top_customers tc ON ti.rank = tc.rank
WHERE 
    (ti.total_net_profit IS NOT NULL OR tc.total_profit IS NOT NULL)
ORDER BY 
    COALESCE(ti.total_net_profit, 0) DESC, 
    COALESCE(tc.total_profit, 0) DESC;