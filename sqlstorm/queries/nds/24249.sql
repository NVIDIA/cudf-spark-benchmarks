
WITH ranked_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_bill_customer_sk) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
filtered_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status 
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status IS NOT NULL
),
customer_sales AS (
    SELECT 
        fc.c_customer_sk,
        COUNT(rs.ws_item_sk) AS total_items,
        MAX(rs.total_net_profit) AS max_profit
    FROM 
        filtered_customers fc 
    LEFT JOIN 
        ranked_sales rs ON fc.c_customer_sk = rs.ws_bill_customer_sk 
    GROUP BY 
        fc.c_customer_sk
)
SELECT 
    c.c_customer_id, 
    cs.total_items, 
    cs.max_profit,
    COALESCE(cs.max_profit, 0) / NULLIF(cs.total_items, 0) AS profit_per_item,
    CASE 
        WHEN cs.total_items = 0 THEN 'No Sales' 
        ELSE 'Sales Made' 
    END AS sales_status
FROM 
    filtered_customers c 
LEFT JOIN 
    customer_sales cs ON c.c_customer_sk = cs.c_customer_sk 
WHERE 
    c.c_customer_id IS NOT NULL
ORDER BY 
    profit_per_item DESC 
LIMIT 10;
