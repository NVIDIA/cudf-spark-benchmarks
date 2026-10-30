
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        ca.ca_state AS customer_state,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY d.d_year, ca.ca_state
),
top_states AS (
    SELECT 
        customer_state,
        sales_year,
        total_net_profit,
        total_orders,
        avg_order_value,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_net_profit DESC) AS profit_rank
    FROM sales_summary
)
SELECT 
    customer_state,
    sales_year,
    total_net_profit,
    total_orders,
    avg_order_value
FROM top_states
WHERE profit_rank <= 5
ORDER BY sales_year, total_net_profit DESC;
