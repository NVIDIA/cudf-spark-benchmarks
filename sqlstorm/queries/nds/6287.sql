
WITH Summary AS (
    SELECT 
        ca_state,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ca_state
),
RankedSummary AS (
    SELECT 
        ca_state,
        total_quantity,
        total_profit,
        total_orders,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
    FROM 
        Summary
)
SELECT 
    ca_state,
    total_quantity,
    total_profit,
    total_orders,
    profit_rank,
    quantity_rank
FROM 
    RankedSummary
WHERE 
    profit_rank <= 10 OR quantity_rank <= 10
ORDER BY 
    total_profit DESC;
