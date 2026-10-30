
WITH customer_purchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT w.ws_order_number) AS total_orders,
        SUM(w.ws_net_paid_inc_tax) AS total_spent,
        AVG(w.ws_quantity) AS avg_items_per_order
    FROM 
        customer AS c
    JOIN 
        web_sales AS w ON c.c_customer_sk = w.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cp.total_orders,
        cp.total_spent,
        cp.avg_items_per_order,
        ROW_NUMBER() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        customer_purchases AS cp
    JOIN 
        customer AS c ON cp.c_customer_id = c.c_customer_id
)
SELECT 
    c.c_customer_id,
    tc.total_orders,
    tc.total_spent,
    tc.avg_items_per_order,
    ca.ca_city,
    ca.ca_state
FROM 
    top_customers AS tc
JOIN 
    customer AS c ON tc.c_customer_id = c.c_customer_id
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
