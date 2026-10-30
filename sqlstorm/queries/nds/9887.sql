
WITH aggregated_sales AS (
    SELECT 
        d.d_year, 
        ca.ca_state, 
        SUM(ws.ws_net_profit) AS total_net_profit, 
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        AVG(case when c.c_birth_year < 1980 then 1 else 0 end) * 100 AS percentage_born_before_1980,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        d.d_year, ca.ca_state
),
ranked_sales AS (
    SELECT 
        d_year,
        ca_state,
        total_net_profit,
        unique_customers,
        percentage_born_before_1980,
        total_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        aggregated_sales
)
SELECT 
    d_year, 
    ca_state, 
    total_net_profit, 
    unique_customers, 
    percentage_born_before_1980, 
    total_orders
FROM 
    ranked_sales
WHERE 
    profit_rank <= 10
ORDER BY 
    d_year, total_net_profit DESC;
