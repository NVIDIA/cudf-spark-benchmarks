
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 5000
    GROUP BY 
        ws_item_sk
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(*) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit,
        MAX(ws_net_profit) AS max_net_profit
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
), 
address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.order_count,
    cs.avg_net_profit,
    cs.max_net_profit,
    sa.address_count,
    ss.total_quantity,
    ss.total_sales_price,
    ss.total_net_profit
FROM 
    customer_summary cs
LEFT JOIN 
    address_summary sa ON sa.address_count > 50
JOIN 
    sales_summary ss ON cs.order_count > 10 AND ss.rank = 1
WHERE 
    cs.max_net_profit IS NOT NULL
ORDER BY 
    cs.avg_net_profit DESC, ss.total_net_profit DESC
LIMIT 100;
