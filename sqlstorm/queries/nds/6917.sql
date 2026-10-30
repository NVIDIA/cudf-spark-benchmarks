
WITH RevenueData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        d.d_year,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year, ca.ca_state
),
RankedData AS (
    SELECT 
        rd.*,
        RANK() OVER (PARTITION BY rd.d_year ORDER BY rd.total_revenue DESC) AS revenue_rank
    FROM 
        RevenueData rd
),
TopStates AS (
    SELECT 
        rd.ca_state,
        SUM(rd.total_revenue) AS state_revenue
    FROM 
        RankedData rd
    WHERE 
        rd.revenue_rank <= 10
    GROUP BY 
        rd.ca_state
)
SELECT 
    ts.ca_state,
    ts.state_revenue,
    COUNT(DISTINCT rd.c_customer_id) AS customer_count,
    AVG(rd.avg_order_value) AS avg_order_value
FROM 
    TopStates ts
JOIN 
    RankedData rd ON ts.ca_state = rd.ca_state
GROUP BY 
    ts.ca_state, ts.state_revenue
ORDER BY 
    ts.state_revenue DESC;
