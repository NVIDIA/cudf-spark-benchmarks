WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        c.c_birth_year,
        ca.ca_state,
        CASE 
            WHEN c.c_birth_year IS NOT NULL THEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year 
            ELSE NULL 
        END AS age,
        d.d_year,
        s.s_store_name
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 1998 AND 2001
),
AggregatedData AS (
    SELECT 
        ca_state,
        age,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        SalesData
    GROUP BY 
        ca_state, age
),
RankedData AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        AggregatedData
)
SELECT 
    ca_state,
    age,
    total_sales,
    total_revenue,
    avg_net_profit
FROM 
    RankedData
WHERE 
    revenue_rank <= 5
ORDER BY 
    ca_state, total_revenue DESC;