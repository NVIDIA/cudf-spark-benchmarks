
WITH Sales_Stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) as total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
), Address_Stats AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(ss.total_net_profit) AS avg_net_profit_per_customer
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        Sales_Stats ss ON ss.c_customer_id = c.c_customer_id
    GROUP BY 
        ca.ca_country
)
SELECT 
    a.ca_country,
    a.customer_count,
    a.avg_net_profit_per_customer,
    CASE 
        WHEN a.customer_count > 100 THEN 'High Density'
        WHEN a.customer_count BETWEEN 50 AND 100 THEN 'Medium Density'
        ELSE 'Low Density'
    END AS customer_density,
    COALESCE(a.avg_net_profit_per_customer, 0) AS adjusted_avg_net_profit
FROM 
    Address_Stats a
WHERE 
    a.avg_net_profit_per_customer IS NOT NULL
ORDER BY 
    a.avg_net_profit_per_customer DESC
LIMIT 10;
