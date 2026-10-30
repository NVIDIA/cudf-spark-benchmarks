
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        co.total_orders,
        co.total_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON c.c_customer_id = co.c_customer_id
    WHERE 
        co.total_orders > 5
    ORDER BY 
        co.total_spent DESC
    LIMIT 10
)
SELECT 
    t.customer_name,
    REPLACE(LOWER(t.customer_name), ' ', '-') AS name_slug,
    t.total_orders,
    ROUND(t.total_spent, 2) AS total_spent_formatted
FROM 
    TopCustomers t
ORDER BY 
    t.total_spent DESC;
