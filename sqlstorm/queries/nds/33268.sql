
WITH  total_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
sales_by_state AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_net_profit) AS state_total_net_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_net_profit,
    cs.avg_purchase_estimate,
    sb.state_total_net_profit,
    ts.ws_sold_date_sk,
    ts.rank
FROM 
    customer_summary cs
LEFT JOIN 
    sales_by_state sb ON cs.total_net_profit = sb.state_total_net_profit
LEFT JOIN 
    total_sales ts ON cs.total_net_profit = ts.ws_net_profit
WHERE 
    cs.total_orders > 5
AND 
    sb.state_total_net_profit IS NOT NULL
ORDER BY 
    cs.total_net_profit DESC, 
    sb.state_total_net_profit DESC
LIMIT 10;
