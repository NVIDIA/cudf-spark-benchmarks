
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        r.c_customer_id,
        r.total_orders,
        r.total_revenue
    FROM 
        RankedSales r
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_orders,
    tc.total_revenue,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    tc.total_revenue DESC;
