
WITH customer_stats AS (
    SELECT 
        ca.ca_state,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ca.ca_state, cd.cd_gender
),
top_states AS (
    SELECT 
        ca_state,
        SUM(customer_count) AS total_customers
    FROM 
        customer_stats
    GROUP BY 
        ca_state
    ORDER BY 
        total_customers DESC 
    LIMIT 5
)
SELECT 
    cs.ca_state, 
    cs.cd_gender,
    cs.customer_count,
    cs.total_net_profit,
    cs.avg_sales_price,
    cs.total_quantity
FROM 
    customer_stats cs
JOIN 
    top_states ts ON cs.ca_state = ts.ca_state
ORDER BY 
    cs.total_net_profit DESC;
