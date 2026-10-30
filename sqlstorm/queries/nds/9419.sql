WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(CASE WHEN cd.cd_gender = 'F' THEN ws.ws_net_profit END) AS avg_net_profit_female,
        AVG(CASE WHEN cd.cd_gender = 'M' THEN ws.ws_net_profit END) AS avg_net_profit_male,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458479 AND 2458480 
    GROUP BY 
        c.c_customer_id
)
SELECT 
    s.c_customer_id,
    s.total_net_profit,
    s.total_orders,
    s.avg_net_profit_female,
    s.avg_net_profit_male
FROM 
    SalesSummary s
JOIN 
    customer c ON s.c_customer_id = c.c_customer_id
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'NY' AND
    s.profit_rank <= 10 
ORDER BY 
    s.total_net_profit DESC;